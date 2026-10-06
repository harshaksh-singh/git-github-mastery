# V167: History rewriting as an operation, and its mechanics seen locally

- **Part.** 7, Security
- **Module.** 31
- **Planned minutes.** 28
- **Prerequisites.** V052, V079, V166
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.16 and 21B.17, with the command safety table of section 21B.23 and the limits of section 21B.22
- **Demo scripts.** `labs/ch21b/rewrite-mechanics.sh` (snippets `01-fresh-mirror-clone` to `08-server-keeps-old-objects`)

## HOOK

**[ON SCREEN]** The question, as a CTO asks it: "You rewrote history to remove a customer data file and force-pushed. Where may the file still exist, and who controls each place?"

A team finds a file in the repository that should never have been there. Somebody searches, finds a command that removes a file from every commit, runs it in the clone on their laptop, force-pushes `main`, and reports that the file is gone. Three things are wrong with that report. The release tag still points at the old commits. The server still holds every old object. And every colleague's clone still holds the complete old history and can push it back with an ordinary push tomorrow morning.

In this video you see a whole-history rewrite the way an operator has to see it: as a change to every ref and to every commit ID after the first affected commit, with a list of owners, an order and a verification. The command is the smallest part.

## INTRODUCTION

In V166 you learned the six steps of a leak response and why containment comes first: the credential is revoked at its issuer before anything is done to the repository. The third step, eradicate, said "rewrite history only where warranted". This video is about that clause.

You already have the two facts that explain everything you are about to see. From V052: a commit's ID is the hash of its content, and its content includes the ID of its parent, so a commit whose parent changes is a different commit. From V079: a forced push moves refs on the remote and deletes no objects.

We will do three things. First, say what the recommended tool, git-filter-repo, requires and records, exactly as section 21B.16 gives it from the tool's manual and from GitHub's procedure. Second, replay the mechanics locally with a command that ships with Git, so that you can watch the refs and the objects. Third, list what the rewrite costs, because the costs are what decide whether you do it at all.

One layer note before we start. Everything in the terminal today is **Git**, on a local bare repository that plays the server. What **GitHub** does with a rewrite is the subject of V168.

## LEARNING OBJECTIVES

After this video you can:

1. Say what a whole-history rewrite replaces and why the command is the smallest part of the work.
2. State what git-filter-repo requires and records, as section 21B.16 gives it from the tool's manual.
3. Follow the mechanics locally: fresh mirror clone, all refs, new IDs, old objects that remain, pruning, the forced push.
4. Explain what happens to signatures and to open pull requests.
5. List the costs that decide against a rewrite.

## CONCEPT

**Why it exists.** Some data stays harmful after its credential is rotated, or cannot be rotated at all: personal data, customer records, proprietary model weights, a private key whose public half is pinned in devices, a secret whose revocation takes weeks. For that data, and only for that data, you want the repository's history to stop containing it.

**What it is, in one sentence.** A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs, and the command is the smallest part of the work.

**How: the recommended tool.** The recommended tool is git-filter-repo. It is a separate program and it is not part of Git. It is not installed in the lab, and this course installs nothing. Section 21B.16 gives five facts about it from its manual and from GitHub's page on removing sensitive data.

**[ON SCREEN]** The five facts, one line at a time.

One. It refuses to run outside a fresh clone unless forced, because the rewrite is irreversible: by default it ends with an immediate pruning of reflogs and old objects.

Two. The option `--sensitive-data-removal` exists since version 2.47. It fetches all refs first and gathers the extra information needed to clean up other copies.

Three. It records its work in `.git/filter-repo/`: a file `commit-map` with the old and new ID of every commit, and the files `ref-map`, `changed-refs` and `first-changed-commits`.

Four. Commits get new IDs, so signatures on commits and tags cannot remain valid and are removed. Signed tags become annotated tags.

Five. By default a full rewrite removes the `origin` remote, as a forcing function against pushing by reflex.

**[ON SCREEN]** GitHub's documented sequence, as a slide. No output is shown, because the tool is not installed here and nothing in this course contacts GitHub.

```bash
# 1. Install the tool (GitHub's page gives this command for macOS). You need version 2.47 or later.
brew install git-filter-repo

# 2. A fresh clone, never your working clone.
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY
cd YOUR-REPOSITORY

# 3a. Remove a file from every commit ...
git-filter-repo --sensitive-data-removal --invert-paths --path PATH-TO-YOUR-FILE-WITH-SENSITIVE-DATA

# 3b. ... or replace strings listed in a file (one expression per line; by default each is
#     literal text and is replaced by ***REMOVED***; "regex:" and "glob:" prefixes exist).
git-filter-repo --sensitive-data-removal --replace-text ../passwords.txt

# 4. How many pull requests are affected? Support will ask.
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs

# 5. Force-push every ref.
git push --force --mirror origin
```

Read the slide as five steps: install, fresh clone, filter by path or by text, count the affected pull requests, force-push every ref. Before the push, the manual's verification is `git log --all --name-status -- <file>` and `git log -S"<string>" --all -p --`. Both must print nothing.

**[ON SCREEN]** Unverified.

One statement here is marked unverified in the textbook, and I say it as the textbook does. Whether git-filter-repo keeps the `origin` remote when `--sensitive-data-removal` is used was not tested for the research report of this course. GitHub's instructions push to `origin` afterwards, and the manual says a default full rewrite removes it. If the push fails for a missing remote, the manual's remedy is `git remote add origin <url>`.

**What makes it an operation.** Around those five commands stand six facts, each with a consequence.

**[ON SCREEN]** The table of section 21B.16, one row at a time.

| Fact | Consequence |
|---|---|
| Other contributors must stop work during the cleanup | announce a freeze; work pushed during the rewrite is discarded or forces a restart |
| All refs, tags included, must be force-pushed | rules that block force pushes and tag updates must be switched off temporarily, and back on afterwards |
| Every descendant commit ID changes | review comments on open pull requests detach; diffs of closed ones break; every recorded ID is stale |
| Signatures are removed, also on commits that predate the removed data | a "require signed commits" rule now rejects the rewritten history unless bypassed |
| Orphaned LFS objects are not removed by the rewrite | they are purged separately |
| Pull request refs, forks and other clones keep the old history | sections 21B.18 and 21B.19, the next video |

Stay on the third and fourth rows, because they answer two of today's objectives. Open pull requests: their review comments are attached to commit IDs and lines, the IDs no longer exist on the branch, so the comments detach, and the diffs of closed pull requests break. Signatures: a signature covers the commit object, the object is replaced, so the signature cannot be carried over. The textbook's row says signatures are removed also on commits that predate the removed data. A rule that requires signed commits therefore rejects the rewritten history unless it is bypassed.

**When not.** Section 21B.22 lists five cases. Do not rewrite for a credential that is revoked and whose provider logs show no use: record the decision and stop. Do not rewrite a public repository in the belief that it un-publishes anything. Do not rewrite before containment. Do not rewrite in your working clone, because the tool prunes reflogs and stashes. And do not have each colleague run the same command: identical commands can produce different IDs.

**[ON SCREEN]** Outdated advice.

Older guides use `git filter-branch` or the BFG Repo-Cleaner. Git's own manual says of `git filter-branch` that its "use is not recommended" and points to git-filter-repo. GitHub's current page documents git-filter-repo only. Keep that in mind for the demonstration, because the demonstration uses `git filter-branch`, for one reason only: it ships with Git, and the lab installs nothing. It is not the recommended tool. It is enough to show four mechanics that are the same whichever tool rewrites: descendants get new IDs, tags must be rewritten too, old objects remain until pruned, and the server keeps them after the push.

## MENTAL MODEL

The textbook's analogy is the recall of a printed book to remove one page. You can reprint every copy in your warehouse. Each reader's copy stays as it was until that reader exchanges it. The page numbers after the removed page all change. Every citation by page number now points at the wrong place. And one reader who lends an old copy to the library puts the page back on the shelf.

Map it. The warehouse is the cleanup clone and the server. The readers' copies are clones and forks. The page numbers are commit IDs. The citations are everything that stored an ID: issue comments, release notes, experiment records, deployment manifests. The reader who lends the old copy is the stale clone of the next video.

Where the analogy breaks: a reprinted book has no memory of the old edition, and a Git repository does. After the rewrite the old objects are still in the object database, unreachable, until something prunes them. The warehouse still has the old copies in the back room.

So the model to carry is this. A rewrite does three separate things, and only the first one is done by the filter: it writes new commits; then refs are moved to them; then, separately and deliberately, old objects are deleted. Each of the three happens per repository. Nothing you do in one repository deletes anything in another.

## DIAGRAM

**[DIAGRAM]** Build the "before" line first, left to right: eight commits on `main`. Mark the fifth, where `.env` was added. Hang `v0.1.0` below the commit before it and `v0.2.0` above the commit after it. Branch `feature/streaming` off the sixth commit.

```text
 before                                              v0.2.0
                                                       |
  dfd59fd--0c55276--6388058--987a49d--0805fd8--64b9b89--b509fe3--d4b8762   main
                                |     (.env added)          \
                              v0.1.0                         7fae871       feature/streaming

 after                                               v0.2.0
                                                       |
  dfd59fd--0c55276--6388058--987a49d--0ac4257--66a99cc--51e2d95--c8ce738   main
                                |     (no .env)             \
                              v0.1.0                         ba9f0e0       feature/streaming

  shared, unchanged: dfd59fd .. 987a49d        replaced: everything from the first changed commit on
```

Now draw the "after" line underneath. The first four commits are the same objects: same IDs, drawn in the same place. From the fifth commit on, every ID is different. Ask the viewer why the sixth, seventh and eighth changed although nobody touched their content. The answer is the parent field. The last line of the diagram is the sentence to remember: shared and unchanged up to the commit before the leak, replaced from the first changed commit on. `v0.1.0` stays where it was. `v0.2.0` has to move, and so does `feature/streaming`.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/rewrite-mechanics`. The caption bar shows `labs/ch21b/rewrite-mechanics.sh`. The secret in this repository is a dummy string that says so in its own text. The IDs on screen equal the IDs in the book, because the replay runs on the fixed lab clock.

**Step 1: a fresh mirror clone.** 🟢 SAFE: a clone creates a new repository. A mirror clone has every ref of the server as a local ref, which is what a rewrite needs.

```bash
git clone -q --mirror server.git cleanup.git
cd cleanup.git
git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"
git log --oneline main
first=$(git log --format=%h --diff-filter=A main -- .env); echo $first
```

Predict: how many refs will the listing show, and of which kinds?

<!-- snippet: ch21b/rewrite-mechanics/01-fresh-mirror-clone -->
```text
$ git clone -q --mirror server.git cleanup.git
$ cd cleanup.git
$ git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"
7fae871 commit refs/heads/feature/streaming
d4b8762 commit refs/heads/main
b4a2514 tag refs/tags/v0.1.0
c38ee42 tag refs/tags/v0.2.0
$ git log --oneline main
d4b8762 Document setup in README
b509fe3 Add request timeout
64b9b89 Add retry with backoff
0805fd8 Add staging settings
987a49d Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ first=$(git log --format=%h --diff-filter=A main -- .env); echo $first
0805fd8
```
<!-- /snippet -->

Point at four refs: two branches and two tags, and the tags are of type `tag`, so they are annotated tag objects. Point at the last line: the commit that added `.env` is `0805fd8`, "Add staging settings". Everything from that commit on is affected. The four commits below it are not.

**Step 2: the mistake first. Rewrite the branches and forget the tags.** 🔴 DANGEROUS. Before running a history filter, the five answers. What it changes: every affected commit and all descendants, on every ref it is given. What it can destroy: signatures, and with a wrong path argument, files you meant to keep. How to preview: git-filter-repo has `--dry-run`; and you run in a fresh clone. How to recover: the untouched server and other clones, until you push. When it is appropriate: for data that stays harmful after rotation. For an unpushed mistake on a private branch a rebase is the smaller tool.

```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' -- --branches > ../filter-1.log 2>&1
grep -v 'seconds passed' ../filter-1.log
git grep -l DUMMY-KEY $(git rev-list --branches) | wc -l
git grep -l DUMMY-KEY $(git rev-list --all) | cut -c1-9,41-
git tag --contains $first
```

Predict: after the branches are rewritten, does a scan over all refs still find the key?

<!-- snippet: ch21b/rewrite-mechanics/02-branches-only -->
```text
# First attempt: rewrite the branches and forget the tags.
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' -- --branches > ../filter-1.log 2>&1
$ grep -v 'seconds passed' ../filter-1.log
Ref 'refs/heads/feature/streaming' was rewritten
Ref 'refs/heads/main' was rewritten
$ git grep -l DUMMY-KEY $(git rev-list --branches) | wc -l
       0
$ git grep -l DUMMY-KEY $(git rev-list --all) | cut -c1-9,41-
d4b876277:.env
7fae87198:.env
b509fe363:.env
64b9b890c:.env
0805fd8e8:.env
$ git tag --contains $first
v0.2.0
```
<!-- /snippet -->

**[PAUSE]** Hold on the two counts. Over the branches: zero. Over all refs: five snapshots that contain the key. The last command says why: the tag `v0.2.0` contains the first affected commit. The tag points at the old commit `64b9b89`, and a tag keeps its commit and all of that commit's ancestors alive. Anyone who fetches the tag fetches the secret. One more detail from the textbook: `--all` also includes the backup refs that `filter-branch` wrote under `refs/original/`.

**Step 3: all refs, with tags following their commits.**

```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter-2.log 2>&1
grep -v 'seconds passed' ../filter-2.log
```

<!-- snippet: ch21b/rewrite-mechanics/03-all-refs -->
```text
# Second attempt: every ref, and --tag-name-filter cat so that tags follow their commits.
$ FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter-2.log 2>&1
$ grep -v 'seconds passed' ../filter-2.log
WARNING: Ref 'refs/heads/feature/streaming' is unchanged
WARNING: Ref 'refs/heads/main' is unchanged
WARNING: Ref 'refs/tags/v0.1.0' is unchanged
Ref 'refs/tags/v0.2.0' was rewritten
v0.1.0 -> v0.1.0 (987a49db5aa45d6cb1e4b10024438f21b8e28444 -> 987a49db5aa45d6cb1e4b10024438f21b8e28444)
v0.2.0 -> v0.2.0 (64b9b890cf46c6a921380d722eaf0b33d790bb9a -> 66a99cccb3cd6ac483eccafadf8c4804770799ea)
```
<!-- /snippet -->

Read three things. The branches are reported "unchanged" because the first run already rewrote them. `v0.1.0` is unchanged because it points before the leak. `v0.2.0` was rewritten and now points at `66a99cc`.

**Step 4: the map of old and new IDs.**

```bash
paste ../before.txt ../after.txt | while read o n; do printf '%s  %s  %s\n' $o $n "$(git log -1 --format=%s $n)"; done
```

Predict: of the eight commits on `main`, how many have a new ID?

<!-- snippet: ch21b/rewrite-mechanics/04-new-ids -->
```text
# old ID, new ID, subject (newest first)
$ paste ../before.txt ../after.txt | while read o n; do printf '%s  %s  %s\n' $o $n "$(git log -1 --format=%s $n)"; done
d4b8762  c8ce738  Document setup in README
b509fe3  51e2d95  Add request timeout
64b9b89  66a99cc  Add retry with backoff
0805fd8  0ac4257  Add staging settings
987a49d  987a49d  Add evaluation harness
6388058  6388058  Add LLM client
0c55276  0c55276  Add answer prompt template
dfd59fd  dfd59fd  Add BM25 retriever
```
<!-- /snippet -->

Four. `0805fd8` became `0ac4257` because its tree changed. The three above it changed although their own content did not: each records its parent's ID, the parent changed, so the hash changed. The four commits below the leak are byte for byte the same objects. This table is what git-filter-repo writes to `commit-map`. In an incident, that file belongs in the incident record, so that old IDs can be translated.

**Step 5: the old objects are still there.** A rewrite adds new objects and moves refs. It deletes nothing by itself.

```bash
git for-each-ref --format="%(objectname:short) %(refname)" refs/original
git cat-file -t $first
git show $first:.env
```

<!-- snippet: ch21b/rewrite-mechanics/05-old-objects-remain -->
```text
$ git for-each-ref --format="%(objectname:short) %(refname)" refs/original
64b9b89 refs/original/refs/tags/v0.2.0
$ git cat-file -t $first
commit
$ git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

`git cat-file -t` answers `commit`: the object exists. `git show` prints the file with the key from it. In this clone, after a rewrite of all refs.

**Step 6: pruning.** 🔴 DANGEROUS. The five answers for `git reflog expire --expire=now --all` followed by `git gc --prune=now`. What it changes: all reflog entries and all unreachable objects are deleted. What it can destroy: every commit, stash and staged blob that only a reflog, or nothing at all, was keeping. Preview: `git fsck --unreachable --no-reflogs` lists what would go. Recovery: none locally. When appropriate: in a cleanup clone, and in a stale clone after its owner has saved their work. In your working clone it also discards every stash.

```bash
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc -q --prune=now
git cat-file -t $first
git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
git fsck --no-progress
```

<!-- snippet: ch21b/rewrite-mechanics/06-prune -->
```text
$ git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
$ git reflog expire --expire=now --all
$ git gc -q --prune=now
$ git cat-file -t $first
fatal: Not a valid object name 0805fd8
[exit status: 128]
$ git grep -l DUMMY-KEY $(git rev-list --all) | wc -l
       0
$ git fsck --no-progress
```
<!-- /snippet -->

Three deliberate steps: delete the backup refs, expire the reflogs, prune. Now `git cat-file -t` fails with "Not a valid object name", the scan prints zero, and `git fsck` prints nothing. git-filter-repo performs this pruning for you at the end of its run, which is why it insists on a fresh clone.

**Step 7: the forced push.** 🔴 DANGEROUS. The five answers before the command is run. What it changes: `git push --force --mirror` sets every ref on the remote to the local value and deletes those the clone lacks. What it can destroy: branches and tags that exist only on the remote. A branch that a colleague pushed after you cloned is removed by your push; that is the mechanical reason for the freeze. Preview: `git push --dry-run --force --mirror origin`. Recovery: another clone that still has the old refs; on GitHub, the instruments of Chapter 13. When appropriate: once, after a freeze, at the end of a verified rewrite. Every other force push uses `--force-with-lease`.

```bash
git push --force --mirror origin 2>&1
```

<!-- snippet: ch21b/rewrite-mechanics/07-force-push -->
```text
$ git push --force --mirror origin 2>&1
To $LAB/ch21b/rewrite-mechanics/server.git
 + 7fae871...ba9f0e0 feature/streaming -> feature/streaming (forced update)
 + d4b8762...c8ce738 main -> main (forced update)
 + c38ee42...17124a2 v0.2.0 -> v0.2.0 (forced update)
```
<!-- /snippet -->

Three forced updates, each with a plus sign: two branches and the tag `v0.2.0`. `v0.1.0` is not listed, because it did not change.

**Step 8: what the server holds now.** Predict before running: after this push, can the server still print the key?

```bash
cd ..
git -C server.git log --oneline -1 main
git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
git -C server.git cat-file -t $first
git -C server.git show $first:.env
git -C server.git fsck --no-progress --unreachable | grep commit
```

<!-- snippet: ch21b/rewrite-mechanics/08-server-keeps-old-objects -->
```text
$ cd ..
$ git -C server.git log --oneline -1 main
c8ce738 Document setup in README
$ git -C server.git grep -l DUMMY-KEY $(git -C server.git rev-list --all) | wc -l
       0
# No ref on the server reaches the old commits any more, and they are still there:
$ git -C server.git cat-file -t $first
commit
$ git -C server.git show $first:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
$ git -C server.git fsck --no-progress --unreachable | grep commit
unreachable commit 0805fd8e82dfc4c6a50cb14514d431dbd43df4cd
unreachable commit b509fe3635defadb4fc29d14c01ca2953ca8cd27
unreachable commit d4b876277f85823455b617a02ea443e6e9afd070
unreachable commit 64b9b890cf46c6a921380d722eaf0b33d790bb9a
unreachable commit 7fae8719801ebfc91df813470f8a380ac13184fc
```
<!-- /snippet -->

**[PAUSE]** This is the output the whole video was built for. No ref on the server reaches the secret. The scan over all refs is clean. And `git show` on the server still prints the key, from a commit that `git fsck` lists as unreachable, with four others. A bare repository of your own can be pruned with `git gc --prune=now`. On GitHub you cannot run that; V168 says who can.

**[ON SCREEN]** The state table of section 21B.17.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| history rewrite in the cleanup clone | rewritten to the new tip (none in a mirror clone) | rewritten | unchanged (still names the branch) | moved to the new tip | every affected branch and tag moved; backup refs or `filter-repo/` metadata written; old objects kept until pruned | unchanged | unchanged |
| `git reflog expire --expire=now --all` then `git gc --prune=now` | unchanged | unchanged | unchanged | unchanged | all reflog entries and all unreachable objects deleted | unchanged | unchanged |
| `git push --force --mirror origin` | unchanged | unchanged | unchanged | unchanged | unchanged | every ref set to the local value; refs missing locally are **deleted**; old objects stay as unreachable | branch and tag refs move; pull request refs are refused; cached views and old objects stay until Support acts |

Read the last two columns of the first two rows: unchanged, unchanged. Nothing you did in the cleanup clone touched the remote until the push, and the push moved refs only.

## COMMON MISTAKES

1. **Rewriting the branches and forgetting the tags.** Root cause: a tag is a ref, and any ref that still points into the old history keeps the old commits and all their ancestors reachable and fetchable.
2. **Declaring the secret removed after the force push.** Root cause: a force push moves refs; the old objects stay on the server as unreachable objects, and in every other clone and fork as ordinary history.
3. **Rewriting in the working clone.** Root cause: the tool finishes by expiring reflogs and pruning, which destroys the local safety net, stashes included.
4. **Taking the mirror clone before the freeze.** Root cause: `git push --force --mirror` deletes every remote ref that the cleanup clone does not have, so a branch pushed in between is removed.
5. **Rewriting before revoking.** Root cause: the damage happens at the issuer, where the key is accepted, and no change to any repository makes a copied key stop working.

## PRODUCTION EXAMPLE

An ML platform team finds that a file with customer support transcripts was committed to the evaluation repository four months ago. This is not a credential. Nothing can be rotated, so the data stays harmful, and the textbook's criterion for a rewrite is met. The lead writes the plan before anyone types a command: a freeze from a stated time, the rules that block force pushes and tag updates switched off for the duration and an owner for switching them back on, a fresh clone on one machine, the verification commands, the count of affected pull requests for the Support request, and the instruction to colleagues about their clones.

Then comes the cost that is specific to an ML team. Every experiment record, model card and deployment manifest that stored a commit ID from the last four months now points at a commit that no longer exists on the remote. The team does not try to edit all of those records. It stores git-filter-repo's `commit-map` file in the incident record, so that anyone who holds an old ID can translate it. And because the repository required signed commits, the lead plans the bypass for the rewritten history in advance, since the signatures are gone.

## PRACTICE EXERCISE

Do Lab 31.1, "The tabletop: a committed secret, from report to prevention", in [`lab-manual/m31-secret-leak-response.md`](../../lab-manual/m31-secret-leak-response.md). It runs entirely in the lab shell, with a bare repository as the server, three clones and a dummy secret.

Before you run the rewrite in the lab, write down three predictions: which refs will be reported as rewritten and which as unchanged; how many of the commits on `main` will have new IDs; and what `git show` of the first affected commit will print on the server after the forced push. Then run it and compare. The lab's questions have no answers in the lab file. Attempt them before you open the answers.

When that is done, the challenge is Exercise 31.5, Level 4, "How far did it get?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q336: "When is a history rewrite the wrong response to a leaked secret? What does it cost?"

Answer it aloud before you open the answers file. A strong answer does four things. It starts with the layer where the damage happens, the issuer, and says what revocation achieves that no repository operation can. It gives the criterion for when a rewrite is warranted at all, with examples of data that cannot be rotated. It names the costs concretely: what happens to clones, to recorded commit IDs, to signatures, to open pull requests, and what the rewrite cannot recall. And it ends with a decision that is written down with its reason. An answer that describes only the filter command has answered a different question.

## RECAP

You should now be able to say these sentences.

- A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs; the ancestors of the first affected commit are untouched.
- git-filter-repo is a separate program; it wants a fresh clone, records a commit map, removes signatures, and prunes at the end.
- All refs have to be rewritten and force-pushed, tags included, because any ref into the old history keeps it alive.
- A rewrite adds objects and moves refs; old objects remain until they are pruned, in every repository separately, and the server keeps them after the push.
- A rewrite is for data that stays harmful after rotation; for a key that was revoked within the hour it costs more than it buys.

## HOMEWORK

Read sections 21B.16 and 21B.17 of the textbook. Then do Exercise 31.4, Level 3, "Review this runbook", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md). In the next video a colleague who never read the freeze message pulls and pushes, and the secret is back on `main` without any forced push.

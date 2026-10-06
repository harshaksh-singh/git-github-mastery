# V109: The fetch conversation, shallow clones, partial clones, and choosing a clone

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 28
- **Prerequisites.** V039, V108
- **Textbook sections.** [Chapter 26](../../textbook/ch26-performance.md), sections 26.10 to 26.13
- **Demo scripts.** `labs/ch26/fetch-conversation.sh`, `labs/ch26/shallow-limits.sh`, `labs/ch26/partial-clone.sh`, `labs/ch26/clone-shapes.sh`

## HOOK

**[ON SCREEN]** "CI clones 3 GB for every job. Proposal: `--depth 1` everywhere."

CI clones 3 GB for every job. Someone proposes `--depth 1` everywhere, and the pipeline gets much faster. Your CTO asks one question before approving it: what breaks?

The uncomfortable answer from Chapter 26: history questions break, silently. Versions, blame, merge bases. The commands exit with status 0 and print a plausible answer that is wrong. And a partial clone is usually what was wanted.

## INTRODUCTION

This is the longest video of the part, and it has one thread: a fetch is a conversation, and every special clone is one more line in that conversation. Once you see the line, you can reason about what the clone holds and what it will cost later.

Four replays from `labs/ch26`: `fetch-conversation.sh`, `shallow-limits.sh`, `partial-clone.sh` and `clone-shapes.sh`. The server is a bare copy of `orbit` reached through a `file://` URL, so that Git uses its real transport.

Labels: `git clone` with `--depth` or `--filter`, `git fetch --unshallow` and `git backfill` are 🟢 SAFE. They add objects and read from the remote. A shallow or partial clone holds fewer objects, not different ones.

## LEARNING OBJECTIVES

After this video you can:

- Describe a fetch as a conversation of wants and haves and say where `--depth` and `--filter` enter it.
- Say what a shallow, a blobless, a treeless and a single-branch clone each hold.
- Name the commands that give wrong or failing answers in a shallow clone.
- Explain on-demand fetching in a partial clone and what fails offline.
- Choose a clone shape for a developer, for CI and for a one-off build.

## CONCEPT

The fetch conversation. In one sentence: a fetch is a short dialogue in which the server advertises what it has, the client says what it wants and what it already has, and the server answers with one pack of the difference.

Four steps are enough to reason about every clone shape.

**[ON SCREEN]** Advertise · Want · Have · Pack.

One, advertise. The server names the protocol version and its capabilities, and the client asks for refs with `ls-refs`. Two, want. The client names the tips it wants. Three, have. The client names commits it has, and the server acknowledges those it knows; this negotiation finds the common boundary. Four, pack. The server enumerates the objects on its side of the boundary and sends them as one packfile.

A clone has nothing to offer, so it sends wants and `done`. Each special clone adds one line. `deepen 1` makes the server stop after one commit per tip. `filter blob:none` makes the server leave out objects the filter rejects. Both are decisions of the server's enumeration. The client receives an ordinary pack either way.

Shallow clones. In one sentence: a shallow clone contains the commits within a given distance of the requested tips and a file that tells Git to pretend the history ends there.

Precisely: `git clone --depth <n>` sends `deepen <n>`. The server sends the commits within that distance with their complete trees and blobs. The client writes the IDs of the boundary commits into `$GIT_DIR/shallow`, and Git treats those commits as if they had no parents. Two side effects matter. `--depth` implies `--single-branch` unless you give `--no-single-branch`. And tags that point behind the boundary do not arrive. Related options: `--shallow-since` and `--shallow-exclude` on clone and fetch, `git fetch --deepen`, and `git fetch --unshallow`.

Partial clones. In one sentence: a partial clone has all of the history's structure and leaves out objects of a chosen kind, which a designated remote has promised to deliver when a command needs them.

`git clone --filter=<spec>` sends `filter <spec>`. Three forms. `blob:none`, called blobless: all commits and trees, no blobs except those the checkout needs. `tree:0`, called treeless: all commits, no trees or blobs except those the checkout needs. And `blob:limit=<n>`: omit blobs of at least that size.

Inside `.git`, the clone records `remote.<name>.promisor=true` and `remote.<name>.partialclonefilter`. Packs from that remote get a `.promisor` file beside them, and an object that is missing but referenced from such a pack counts as promised, not as corruption. When a command needs a missing object, Git fetches it from the promisor remote, without asking you.

**[ON SCREEN]** "GitHub, not Git."

Whether a filter is honoured is the server's decision. GitHub supports partial clone. A self-hosted server needs `uploadpack.allowFilter`.

`--single-branch` is the fourth shape. It narrows the refspec to one branch. It limits history by reachability, not by depth.

Failure modes, one per shape. Shallow: wrong answers without a warning. Partial: slowness when a command fetches objects one request at a time, and failure when the promisor remote cannot be reached. Single-branch: other branches are not there, and the refspec stays narrow until you widen it.

When to use which is the table at the end of section 26.13, and we will end the demonstration on it.

## MENTAL MODEL

Two analogies from the textbook, one for each kind of incomplete clone.

A shallow clone is the last page of a ledger, photocopied. It is enough to see today's balance and useless for an audit, and if you forget that it is a photocopy of one page you will conclude that the business started yesterday. The analogy breaks in one direction: unlike a photocopy, a shallow clone can be deepened later.

A partial clone is a book whose footnotes are kept at the publisher. The text is complete, every footnote number is there, and when you look one up it is sent to you and stays in your copy. Read offline, the footnotes you never looked up are unavailable. The analogy breaks at who looks things up: here it is any Git command, without asking you.

The difference between the two is the difference between not knowing and knowing what you lack. A shallow clone has been told the history ends. A partial clone knows exactly which objects exist and where to get them.

## DIAGRAM

**[DIAGRAM]** One repository, `orbit`, five clones. Each row shows what arrived.

```text
  orbit on the server: 96 commits, 284 trees, 122 blobs, 5 tags

  clone                  commits   trees   blobs   tags   what is left out
  full                   [ 96 ]    [284]   [122]   [5]    nothing
  --single-branch        [ 94 ]    [278]   [120]   [5]    what only the other branch reaches
  --depth 1              [  1 ]    [ 20]   [ 33]   [1]    everything behind the boundary commit
  --filter=blob:none     [ 96 ]    [284]   [ 33]   [5]    blobs outside the checkout   (promised)
  --filter=tree:0        [ 96 ]    [ 20]   [ 33]   [5]    trees and blobs outside the checkout (promised)
```

Read the commits column first. Full and both partial clones have all 96 commits. Single-branch has 94: the two commits of the other branch are missing. Depth 1 has one.

Now the blobs column. Thirty-three appears three times. Thirty-three is the number of files in the checkout. The shallow clone and both partial clones hold exactly one snapshot's worth of file content.

So what separates `--depth 1` from `--filter=blob:none`? The commits and the trees. The blobless clone has the whole structure of history and can answer history questions. The shallow clone cannot. And the last column says how each treats what it lacks: the shallow clone pretends it does not exist; the partial clones hold a promise.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch26/fetch-conversation
```

```bash
GIT_TRACE_PACKET=1 git ls-remote "file://$PWD/server/orbit.git" HEAD 2>&1 | sed -n 's/.*packet: *ls-remote< //p' | sed -n '1,/^0000/p'
```

<!-- snippet: ch26/fetch-conversation/01-capabilities -->
```text
# What the serving side says it can do for a fetch:
$ GIT_TRACE_PACKET=1 git ls-remote "file://$PWD/server/orbit.git" HEAD 2>&1 | sed -n 's/.*packet: *ls-remote< //p' | sed -n '1,/^0000/p'
version 2
agent=git/2.55.0-Darwin
ls-refs=unborn
fetch=shallow wait-for-done filter
server-option
object-format=sha1
0000
```
<!-- /snippet -->

Step one, advertise. Protocol version 2. The line `fetch=shallow wait-for-done filter` is the server saying which extras its `fetch` command supports. `filter` appears only because the lab server sets `uploadpack.allowFilter`.

```bash
GIT_TRACE_PACKET="$PWD/full.trace" git clone -q "file://$PWD/server/orbit.git" full
```

**[PAUSE]** A full clone. How many `have` lines does the client send?

<!-- snippet: ch26/fetch-conversation/02-full-clone -->
```text
# A full clone, with the conversation written to a file beside it:
$ GIT_TRACE_PACKET="$PWD/full.trace" git clone -q "file://$PWD/server/orbit.git" full
# The request names one tip per ref it wants, has nothing to offer, and says so:
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -c '^want'
8
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -c '^have'
0
$ sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,$p' | grep -v -e '^want' | tr '\n' ' '
command=fetch agent=git/2.55.0-Darwin object-format=sha1 0001 thin-pack no-progress ofs-delta done 0000 
# The answer is one section, the pack:
$ sed -n 's/.*packet: *clone< //p' full.trace | grep -e acknowledgments -e shallow-info -e packfile
packfile
```
<!-- /snippet -->

Eight wants, one per ref. Zero haves: a clone has nothing to offer. The answer is one section, the pack.

<!-- snippet: ch26/fetch-conversation/03-shallow-and-partial -->
```text
# A shallow clone adds one line to the request, and the answer starts with the boundary:
$ GIT_TRACE_PACKET=1 git clone --depth 1 "file://$PWD/server/orbit.git" shallow 2>&1 | sed -n 's/.*packet: *\(clone[<>]\)/\1/p' | grep -e deepen -e shallow
clone< fetch=shallow wait-for-done filter
clone> deepen 1
clone< shallow-info
clone< shallow 100bb993157cac87afe81008782cd27cd39f8c9d
# A partial clone adds one line as well:
$ GIT_TRACE_PACKET=1 git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless 2>&1 | sed -n 's/.*packet: *\(clone[<>]\)/\1/p' | grep -e 'filter '
clone> filter blob:none
```
<!-- /snippet -->

Here are the two extra lines. `deepen 1`, and the answer begins with a `shallow-info` section naming the commit where history was cut. And `filter blob:none`.

```bash
cd full
GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\(fetch[<>]\)/\1/p' | sed -n '/command=fetch/,$p' | grep -e want -e have -e done -e ACK -e ready -e packfile | cut -c1-60
git log --oneline -3 origin/main
```

<!-- snippet: ch26/fetch-conversation/04-incremental -->
```text
# Later, the server has two new commits. The client names what it wants and what it has:
$ cd full
$ GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\(fetch[<>]\)/\1/p' | sed -n '/command=fetch/,$p' | grep -e want -e have -e done -e ACK -e ready -e packfile | cut -c1-60
fetch> want 9ea7ebd6450f44a34cc11c227de15f7d2837a510
fetch> have 100bb993157cac87afe81008782cd27cd39f8c9d
fetch> have 88222b7043b92ba564af0aefc4acd25af9ef15e2
fetch> have f5915c95c140a7bfddf0cc4b9da258aa5bebe3a2
fetch> have 52ee19bf6e6ff1d7594abe2f2ecc1ac5523a2061
fetch> have 153c8285ef8f669100822c87e96585b181a79b09
fetch< ACK 100bb993157cac87afe81008782cd27cd39f8c9d
fetch< ACK 88222b7043b92ba564af0aefc4acd25af9ef15e2
fetch< ACK f5915c95c140a7bfddf0cc4b9da258aa5bebe3a2
fetch< ACK 52ee19bf6e6ff1d7594abe2f2ecc1ac5523a2061
fetch< ACK 153c8285ef8f669100822c87e96585b181a79b09
fetch< ready
fetch< packfile
$ git log --oneline -3 origin/main
9ea7ebd docs: add note 2
12adbc3 docs: add note 1
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

An ordinary fetch, later. One wanted tip. Five haves. The server acknowledges them, says `ready`, and sends a pack of the two new commits with their trees and blobs.

**[TERMINAL]** The shapes.

```bash
labs/run ch26/clone-shapes
```

```bash
git clone "file://$PWD/server/orbit.git" full
git -C full cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
```

<!-- snippet: ch26/clone-shapes/01-full -->
```text
$ git clone "file://$PWD/server/orbit.git" full
Cloning into 'full'...
$ git -C full cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
$ git -C full for-each-ref --format="%(refname)" | wc -l
       9
```
<!-- /snippet -->

```bash
git clone --single-branch "file://$PWD/server/orbit.git" single
```

<!-- snippet: ch26/clone-shapes/02-single-branch -->
```text
$ git clone --single-branch "file://$PWD/server/orbit.git" single
Cloning into 'single'...
$ git -C single cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
 120 blob
  94 commit
   5 tag
 278 tree
$ git -C single branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

The saving is the two commits of the other branch with their trees and blobs. It pays off when a repository has long-lived branches with large unshared histories, and hardly at all otherwise.

```bash
git clone --depth 1 "file://$PWD/server/orbit.git" shallow
```

<!-- snippet: ch26/clone-shapes/03-shallow -->
```text
$ git clone --depth 1 "file://$PWD/server/orbit.git" shallow
Cloning into 'shallow'...
$ git -C shallow cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
  33 blob
   1 commit
   1 tag
  20 tree
$ git -C shallow log --oneline
100bb99 schemas, gateway, ingest: add the tenant field in one change
$ git -C shallow tag -l | wc -l
       1
```
<!-- /snippet -->

One commit, its 20 trees and 33 blobs: one complete snapshot. And one tag of five.

**[TERMINAL]** Inside the shallow clone.

```bash
labs/run ch26/shallow-limits
```

```bash
git rev-parse --is-shallow-repository
cat .git/shallow
git cat-file -p HEAD | sed -n 1,2p
git log --format='%h parents:[%p] %s'
git cat-file -t HEAD~1
git config get --all remote.origin.fetch
```

**[PAUSE]** The commit object of HEAD: does it still have a `parent` header?

<!-- snippet: ch26/shallow-limits/01-inside -->
```text
$ git rev-parse --is-shallow-repository
true
$ cat .git/shallow
100bb993157cac87afe81008782cd27cd39f8c9d
# The commit object is unchanged and still names its parent. Git has been told to stop there:
$ git cat-file -p HEAD | sed -n 1,2p
tree f2e47b39bb31b7f1afa42bfb51fa6919b4aa3842
parent d259a34f3117e4516fb2f7c071b2dd9c8edc9e5b
$ git log --format='%h parents:[%p] %s'
100bb99 parents:[] schemas, gateway, ingest: add the tenant field in one change
$ git cat-file -t HEAD~1
fatal: Not a valid object name HEAD~1
[exit status: 128]
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
```
<!-- /snippet -->

It does: it names `d259a34`. An object cannot be altered without changing its ID. What changed is Git's reading: the ID in `.git/shallow` makes every walk stop there, `%p` prints no parent, and `HEAD~1` does not resolve.

```bash
git rev-list --count HEAD
git log --oneline -- services/ranker | wc -l
git blame -s services/gateway/routes.py | sed -n 1,3p
git shortlog -sn HEAD
git describe --match 'gateway/v*'
git commit-graph write --reachable
ls .git/objects/info
```

**[PAUSE]** Before each answer appears, say what the full repository would answer: 94 commits, 13 commits on the ranker. What will this clone say, and with what exit status?

<!-- snippet: ch26/shallow-limits/02-wrong-answers -->
```text
# Questions about history get short or wrong answers, without a warning:
$ git rev-list --count HEAD
1
$ git log --oneline -- services/ranker | wc -l
       1
$ git blame -s services/gateway/routes.py | sed -n 1,3p
^100bb99  1) ROUTES = [
^100bb99  2)     ("GET", "/healthz"),
^100bb99  3)     ("POST", "/v1/search/1"),
$ git shortlog -sn HEAD
     1	Lab User
$ git describe --match 'gateway/v*'
fatal: No names found, cannot describe anything.
[exit status: 128]
# A commit-graph cannot be written while the history is cut off. Git says nothing:
$ git commit-graph write --reachable
[exit status: 0]
$ ls .git/objects/info
[exit status: 0]
```
<!-- /snippet -->

This is the danger. Every command exits with status 0 and a plausible answer: one commit in history, one commit that ever touched the ranker, every line of the file blamed on the boundary commit, which the caret marks, and one author. Only `git describe` fails loudly, because the gateway tags lie behind the boundary. And `git commit-graph write` writes nothing, without a message.

**[ON SCREEN]** The root-cause box of section 26.11.

```text
Observed behavior : a version string, a changelog or a "who changed this" report produced in CI is
                    wrong or empty, while the same command on a laptop is right.
Git state         : "git rev-parse --is-shallow-repository" prints true; .git/shallow exists.
Mechanism         : history walks stop at the boundary commits and report what they saw.
Root cause        : the job needed history and was given a snapshot.
Why Git does this : a shallow repository is defined as complete up to its boundary. Git cannot know
                    that your question reaches further.
Correct fix       : "git fetch --unshallow", or enough depth plus tags; or a blobless clone.
Prevention        : shallow clones only where the job reads one snapshot and is thrown away.
```

```bash
git fetch --deepen=5
git rev-list --count HEAD
cat .git/shallow
```

<!-- snippet: ch26/shallow-limits/03-deepen -->
```text
$ git fetch --deepen=5
$ git rev-list --count HEAD
6
$ cat .git/shallow
8d17b5e4d7bcbb52ee1b37a94a03d6704394b4db
$ git log --oneline -- services/ranker | wc -l
       1
```
<!-- /snippet -->

```bash
git fetch --unshallow
git rev-parse --is-shallow-repository
git rev-list --count HEAD
git describe --match 'gateway/v*'
git config get --all remote.origin.fetch
```

<!-- snippet: ch26/shallow-limits/04-unshallow -->
```text
$ git fetch --unshallow
From file://$LAB/ch26/shallow-limits/server/orbit
 * [new tag]         gateway/v1.0.0 -> gateway/v1.0.0
 * [new tag]         gateway/v1.1.0 -> gateway/v1.1.0
 * [new tag]         ranker/v0.9.0 -> ranker/v0.9.0
 * [new tag]         schemas/v1.0.0 -> schemas/v1.0.0
$ git rev-parse --is-shallow-repository
false
$ ls .git/shallow
ls: .git/shallow: No such file or directory
[exit status: 1]
$ git rev-list --count HEAD
94
$ git describe --match 'gateway/v*'
gateway/v1.1.0-28-g100bb99
# The refspec is still the narrow one that --depth implied (Chapter 12, section 12.12):
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
```
<!-- /snippet -->

`--deepen=5` moved the boundary five commits back. `--unshallow` removed it and brought the tags: 94 commits, and `git describe` answers. One thing did not change: the refspec is still the narrow one that `--depth` implied. The clone still follows `main` only.

**[TERMINAL]** Partial clone.

<!-- snippet: ch26/clone-shapes/04-blobless -->
```text
$ git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless
Cloning into 'blobless'...
$ git -C blobless cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c
warning: This repository uses promisor remotes. Some objects may not be loaded.
  33 blob
  96 commit
   5 tag
 284 tree
$ git -C blobless rev-list --count --all
96
$ git -C blobless ls-files | wc -l
      33
```
<!-- /snippet -->

All 96 commits, all 284 trees, and 33 blobs. `git cat-file` warns that it lists only what is local.

```bash
labs/run ch26/partial-clone
```

```bash
git config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"
git rev-list --objects --all --missing=print | grep -c '^?'
git fsck
```

<!-- snippet: ch26/partial-clone/01-promisor -->
```text
$ git config get --all --show-names --regexp "^remote\.origin\.(promisor|partialclonefilter)$"
remote.origin.promisor true
remote.origin.partialclonefilter blob:none
# Two packs arrived: commits and trees at clone time, then the blobs of the checkout.
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   2 idx
   2 pack
   2 promisor
   2 rev
$ for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn
     385
      33
# Objects that the history refers to and this repository does not hold:
$ git rev-list --objects --all --missing=print | grep -c '^?'
89
# Git does not call that damage:
$ git fsck
[exit status: 0]
```
<!-- /snippet -->

Eighty-nine objects that the history refers to are absent, and `git fsck` exits 0. Git does not call that damage. The packs carry `.promisor` files.

**[PAUSE]** Three commands: `git show` of an old file version, `git log` on a path, `git diff --stat`. Which of them contact the server?

<!-- snippet: ch26/partial-clone/02-on-demand -->
```text
# A command that needs an old version of a file fetches it, without being asked:
$ GIT_TRACE=1 git show HEAD~20:services/ranker/features.py 2>&1 >/dev/null | sed -n 's/.*trace: run_command: git //p' | grep -v -e '^pack-objects' -e '^index-pack' -e '^maintenance'
-c fetch.negotiationAlgorithm=noop fetch origin --no-tags --no-write-fetch-head --recurse-submodules=no --filter=blob:none --stdin
$ ls .git/objects/pack/*.pack | wc -l
       3
# Commands that only read commits and trees fetch nothing:
$ git log --oneline -- services/ranker | wc -l
      13
$ git diff --name-status HEAD~10 HEAD -- services | wc -l
       5
$ ls .git/objects/pack/*.pack | wc -l
       3
# Counting changed lines needs file contents. Git asks for all of them in one request:
$ GIT_TRACE=1 git diff --stat HEAD~10 HEAD -- services 2>&1 | grep -c 'run_command: git .*fetch'
1
$ ls .git/objects/pack/*.pack | wc -l
       4
```
<!-- /snippet -->

`git show` of an old version triggered a `git fetch` for one object, with negotiation switched off. Commands that read only commits and trees, `git log` on a path and `git diff --name-status`, fetched nothing: the pack count stays at three. `git diff --stat` needed contents and fetched them in one request.

<!-- snippet: ch26/partial-clone/03-one-by-one -->
```text
# A patch needs both versions of the file for every commit shown: one request per commit.
$ GIT_TRACE=1 git log -p --format=%s -- services/ingest/settings.py 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
11
# Blame walks one version at a time as well:
$ GIT_TRACE=1 git blame pipelines/training/config.yaml 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
12
$ ls .git/objects/pack/*.pack | wc -l
      27
$ git rev-list --objects --all --missing=print | grep -c '^?'
60
```
<!-- /snippet -->

This is the cost. `git log -p` on one file made 11 separate requests and `git blame` made 12, each a round trip to the server, and the repository now holds 27 packs. The manual of `git backfill` describes it in the same terms: such commands "become very slow as they download the missing blobs in single-blob requests".

```bash
git backfill
git maintenance run
```

<!-- snippet: ch26/partial-clone/04-backfill -->
```text
# git backfill (experimental) asks for the missing blobs of the current branch in batches:
$ GIT_TRACE=1 git backfill 2>&1 | grep -c 'run_command: git .*fetch'
1
$ git rev-list --objects --all --missing=print | grep -c '^?'
2
# What is still missing belongs to another branch:
$ git rev-list --objects HEAD --missing=print | grep -c '^?'
0
$ ls .git/objects/pack/*.pack | wc -l
      28
```
<!-- /snippet -->

<!-- snippet: ch26/partial-clone/05-consolidate -->
```text
# Many small packs are the price of on-demand fetching. Maintenance merges them:
$ git maintenance run
$ ls .git/objects/pack | cut -d. -f2 | sort | uniq -c
   1 idx
   1 multi-pack-index
   1 pack
   1 promisor
   1 rev
```
<!-- /snippet -->

`git backfill` is experimental and needs Git 2.49 or later. It fetched everything reachable from HEAD in one batch; the two objects still missing belong to the other branch. Maintenance then merged 28 packs into one promisor pack.

Now take the server away.

**[PAUSE]** The server is unreachable. Does `git log` work? Does `git switch` to a branch whose files were never fetched? And if it fails, in what state does it leave the working tree?

<!-- snippet: ch26/partial-clone/06-offline -->
```text
# A second blobless clone, and the server becomes unreachable:
$ cd ..
$ git clone -q --filter=blob:none "file://$PWD/server/orbit.git" laptop
$ mv server server-offline
$ cd laptop
# What is local still works:
$ git log --oneline -2
100bb99 schemas, gateway, ingest: add the tenant field in one change
d259a34 docs: record architecture change 12
$ git status --short --branch
## main...origin/main
# What needs a missing blob does not:
$ git show HEAD~20:services/ranker/features.py
fatal: '$LAB/ch26/partial-clone/server/orbit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 3b82e45dc30fa47e6f6aa66193090e2b590f7da5 from promisor remote
[exit status: 128]
$ git switch feature/rerank-cache
fatal: '$LAB/ch26/partial-clone/server/orbit.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
fatal: could not fetch 03ada008385944bed720efa38fd6346db17f4169 from promisor remote
[exit status: 128]
$ git status --short --branch
## main...origin/main
$ mv ../server-offline ../server
$ git switch feature/rerank-cache
Switched to a new branch 'feature/rerank-cache'
branch 'feature/rerank-cache' set up to track 'origin/feature/rerank-cache'.
```
<!-- /snippet -->

Everything local works. Anything that needs a missing blob fails with "could not fetch ... from promisor remote". `git switch` failed before touching the working tree: `git status` afterwards still shows `main`, clean.

**[TERMINAL]** Two last shapes from `clone-shapes`.

<!-- snippet: ch26/clone-shapes/05-treeless -->
```text
$ git clone --filter=tree:0 "file://$PWD/server/orbit.git" treeless
Cloning into 'treeless'...
$ git -C treeless cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
  33 blob
  96 commit
   5 tag
  20 tree
$ git -C treeless rev-list --count --all
96
# A path-limited log needs the trees of every commit, and asks for them one commit at a time:
$ GIT_TRACE=1 git -C treeless log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'
93
$ ls treeless/.git/objects/pack/*.pack | wc -l
      96
```
<!-- /snippet -->

Treeless: only the 20 trees of the checkout are present, so a walk that looks at paths must fetch trees. One `git log` on a path sent 93 requests and left 96 packs behind.

<!-- snippet: ch26/clone-shapes/06-filter-ignored -->
```text
# A path instead of a URL: the local transport copies files and ignores the filter.
$ git clone --filter=blob:none server/orbit.git by-path
Cloning into 'by-path'...
warning: --filter is ignored in local clones; use file:// instead.
done.
$ git -C by-path cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
# A server that does not allow filters (uploadpack.allowFilter is false unless set):
$ git -C server/orbit.git config set uploadpack.allowFilter false
$ git clone --filter=blob:none "file://$PWD/server/orbit.git" refused
Cloning into 'refused'...
warning: filtering not recognized by server, ignoring
$ git -C refused cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c
 122 blob
  96 commit
   5 tag
 284 tree
# Both clones are complete, and both are nevertheless configured as partial clones:
$ git -C refused config get remote.origin.partialclonefilter
blob:none
$ git -C server/orbit.git config set uploadpack.allowFilter true
```
<!-- /snippet -->

Two traps. A local path makes `git clone` copy files, so the filter is ignored; use a `file://` URL. And a server without `uploadpack.allowFilter` ignores the filter. In both cases you get a warning, a complete clone, and a repository that is still configured as partial.

**[ON SCREEN]** The choice table of section 26.13.

A developer on a large repository: blobless, with sparse-checkout if the tree is wide. A CI job that builds one snapshot and is discarded: shallow. A CI job that computes versions, changelogs or affected projects: blobless, or full depth. A mirror, a backup, a server: full. A machine without a route to the server: full, or a bundle, which is the next video.

## COMMON MISTAKES

1. Using `--depth 1` for a job that computes a version or a changelog. Root cause: the job needed history and was given a snapshot; walks stop at the boundary and report what they saw.
2. Expecting all branches and tags after `--depth`. Root cause: `--depth` implies `--single-branch`, and tags behind the boundary do not arrive.
3. Running `git log -p` or `git blame` across history in a fresh blobless clone and blaming the network. Root cause: these commands fetch missing blobs in single-blob requests.
4. Using a treeless clone for development. Root cause: any walk that looks at paths must fetch trees, one commit at a time.
5. Testing a filter with a local path. Root cause: the local transport copies files and ignores the filter; a `file://` URL uses the real transport.

## PRODUCTION EXAMPLE

A backend team's release job tags builds with `git describe` and generates a changelog from `git log`. After the switch to `--depth 1`, the version string is empty on some days and the changelog has one line. On laptops the same commands are right. The diagnosis is one command: `git rev-parse --is-shallow-repository` prints true.

Their fix follows the table. Jobs that build one snapshot and are thrown away stay shallow. The release job, which computes versions and changelogs, becomes a blobless clone. That matches GitHub's own guidance, which the textbook cites: shallow clones belong in builds that are thrown away, because later fetches into a shallow repository are expensive for the server and history commands break; blobless clones are recommended for developers, and treeless clones only for builds that need the commit history and nothing else. Note also from the chapter that `actions/checkout` produces a shallow, tagless clone by default.

## PRACTICE EXERCISE

Do Lab 18.1, "Clone one repository three ways and compare what arrived", in [`lab-manual/m18-transfer-scale.md`](../../lab-manual/m18-transfer-scale.md). Before you count, write down for each clone how many commits, trees and blobs you expect, as "all" or "one snapshot". Before each history question, predict whether the answer will be right, wrong, or fetched on demand.

The challenge is Exercise 18.7, "A merge base that is not there", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 448 of the CTO question bank:

> "Compare shallow, blobless and treeless clones: what each holds, what each answers correctly, and what each costs later."

A strong answer is organised as the question is: holds, answers, costs, for each of the three. It is exact about commits, trees and blobs. For "answers correctly" it distinguishes a wrong answer from a slow one. For "costs later" it covers the server as well as the client, and it ends with a recommendation per kind of job.

## RECAP

You should now be able to say:

- A fetch is advertise, want, have, pack; `--depth` adds `deepen`, `--filter` adds `filter`.
- A shallow clone has a boundary recorded in `.git/shallow` and answers history questions wrongly without warning.
- A blobless clone has every commit and tree and fetches blobs on demand from its promisor remote; a treeless clone also lacks trees.
- A partial clone fails only where a missing object is needed and the remote cannot be reached.
- Shallow for a discarded snapshot build; blobless for developers and for jobs that read history; full for mirrors, backups and servers.

## HOMEWORK

Read sections 26.10 to 26.13 of [Chapter 26](../../textbook/ch26-performance.md). Do Exercise 18.1, "A shallow clone, and what it lacks", Exercise 18.2, "A blobless clone fetches on demand", Exercise 18.4, "A clone of depth 2", and Exercise 18.5, "A single-branch clone", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

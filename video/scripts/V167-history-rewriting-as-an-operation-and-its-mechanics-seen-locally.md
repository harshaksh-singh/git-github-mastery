# V167: History rewriting as an operation, and its mechanics seen locally

- **Part.** 7, Security
- **Module.** 31
- **Planned minutes.** 28
- **Prerequisites.** V052, V079, V166
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.16 and 21B.17, with the command safety table of section 21B.23 and the limits of section 21B.22
- **Demo scripts.** `labs/ch21b/rewrite-mechanics.sh` (snippets `01-fresh-mirror-clone` to `08-server-keeps-old-objects`)

## HOOK

**[ON SCREEN]** The question, as a CTO asks it: "You rewrote history to remove a customer data file and force-pushed. Where may the file still exist, and who controls each place?"

A team finds a file in the repository that should never have been there. Somebody searches, finds a command that removes a file from every commit, runs it in the clone on their laptop, force-pushes `main`, and reports that the file is gone.

**[ANIMATION]** cards: question=The_report:_the_file_is_gone cards=The_release_tag:still_points_at_the_old_commits|The_server:still_holds_every_old_object|Every_colleague's_clone:still_holds_the_complete_old_history marks=1:ring,2:ring,3:ring title=Three_things_are_wrong

Three things are wrong with that report. The release tag still points at the old commits. The server still holds every old object. And every colleague's clone still holds the complete old history, and can push it back with an ordinary push tomorrow morning.

**[ANIMATION]** end

Today you see a whole-history rewrite the way an operator has to see it: as a change to every ref and to every commit ID after the first affected commit, with a list of owners, an order and a verification. The command is the smallest part. Keep one question in mind. After that force-push, can the server still print the file? The terminal will answer.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Four words first. A commit is one saved snapshot of the whole project. A repository is the store that holds the commits, and a clone is a copy of it on one machine. A ref is a name that holds the ID of a commit: every branch and every tag is a ref.

In video 166 you learned the six steps of a leak response, and why containment comes first: the credential is revoked at its issuer, the service that accepts it, before anything is done to the repository. The third step, eradicate, said "rewrite history only where warranted". This video is about that clause.

You already have the two facts that explain everything you're about to see.

**[ANIMATION]** hash: differs=byte left=a_commit right=the_same_commit,_another_parent lines=tree:_the_snapshot|parent:_the_commit_it_was_built_on|author,_date,_message change=2 alt=parent:_a_replaced_commit ids=one-ID,another-ID diff=Another_parent,_another_ID steps=one,different title=The_ID_is_computed_from_the_content at_different=55

From video 52: a commit's ID is the hash of its content, a fingerprint computed from its bytes, and that content includes the ID of its parent, the commit it was built on. So a commit whose parent changes is a different commit.

**[ANIMATION]** remotes: [your clone] A-B-C′ main; HEAD=none || [the server] A-B-C main; HEAD=none => || [the server] + B-C′ main; ghost:C; cmd:!git_push_--force; say:The_ref_moves._No_object_is_deleted title=A_forced_push at_state_2=40

From video 79: a forced push moves refs on the remote, here the server, and deletes no objects. An object is one stored unit in Git, such as a commit or the content of a file.

**[ANIMATION]** end

Three things today. First, what the recommended tool, git-filter-repo, requires and records, as section 21B.16 gives it from the tool's manual and from GitHub's procedure. Second, the mechanics, replayed locally with a command that ships with Git, so that you can watch the refs and the objects. Third, what the rewrite costs, because the costs decide whether you do it at all.

**[ANIMATION]** sandbox: steps=room,inside name=The_rewrite_lab inside=server.git:_the_bare_server,cleanup.git:_a_mirror_clone,a_dummy_secret title=Everything_today_is_Git,_in_the_lab

One layer note before we start. Everything in the terminal today is **Git**, on a local bare repository that plays the server. A bare repository holds history only, with no files to edit, as a server does. What **GitHub** does with a rewrite is the subject of video 168.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Say what a whole-history rewrite replaces and why the command is the smallest part of the work.
2. State what git-filter-repo requires and records, as section 21B.16 gives it from the tool's manual.
3. Follow the mechanics locally: fresh mirror clone, all refs, new IDs, old objects that remain, pruning, the forced push.
4. Explain what happens to signatures and to open pull requests.
5. List the costs that decide against a rewrite.

## CONCEPT

**Why it exists.** Some data stays harmful after its credential is rotated, or can't be rotated at all: personal data, customer records, proprietary model weights, a private key whose public half is pinned in devices, a secret whose revocation takes weeks. For that data, and only for that data, you want the repository's history to stop containing it.

**[ANIMATION]** graph: A-B-C-D-E main; HEAD=none; note:C:first_affected => + B-C′-D′-E′ main; ghost:C,D,E; say:The_first_affected_commit_and_every_descendant_are_replaced title=A_whole-history_rewrite at_state_2=30

**What it is, in one sentence.** A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs, and the command is the smallest part of the work. Descendants are the commits built on top of it.

**[ANIMATION]** end

**How: the recommended tool.** The recommended tool is git-filter-repo. It's a separate program and it isn't part of Git. It isn't installed in the lab, and this course installs nothing. Section 21B.16 gives five facts about it from its manual and from GitHub's page on removing sensitive data.

**[ON SCREEN]** The five facts, one line at a time.

**[ANIMATION]** cards: question=git-filter-repo,_as_section_21B.16_gives_it numbered=on cards=Wants_a_fresh_clone:it_ends_by_pruning_reflogs_and_old_objects|--sensitive-data-removal:since_version_2.47;_fetches_all_refs_first|Records_its_work:.git/filter-repo/commit-map|Signatures_are_removed:signed_tags_become_annotated_tags|Removes_the_origin_remote:by_default,_in_a_full_rewrite id=facts

**[ANIMATION]** step: facts.1

One. It refuses to run outside a fresh clone unless forced, because the rewrite is irreversible: by default it ends with an immediate pruning of reflogs and old objects. A reflog is a clone's own list of where each ref has pointed, and pruning means deleting.

**[ANIMATION]** step: facts.2

Two. The option `--sensitive-data-removal` exists since version 2.47. It fetches all refs first and gathers the extra information needed to clean up other copies.

**[ANIMATION]** step: facts.3

Three. It records its work in `.git/filter-repo/`: a file `commit-map` with the old and new ID of every commit, and the files `ref-map`, `changed-refs` and `first-changed-commits`.

**[ANIMATION]** step: facts.4

Four. Commits get new IDs, so signatures on commits and tags can't remain valid and are removed. A signature is a cryptographic seal over the bytes of one commit or one annotated tag. Signed tags become annotated tags.

**[ANIMATION]** step: facts.5

Five. By default a full rewrite removes the `origin` remote, as a forcing function against pushing by reflex. `origin` is the name under which a clone remembers the repository it came from.

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

One statement here is marked unverified in the textbook, and I say it as the textbook does. Whether git-filter-repo keeps the `origin` remote when `--sensitive-data-removal` is used wasn't tested for the research report of this course. GitHub's instructions push to `origin` afterwards, and the manual says a default full rewrite removes it. If the push fails for a missing remote, the manual's remedy is `git remote add origin <url>`.

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

Stay on the third and fourth rows, because they answer two of today's objectives. A pull request is a GitHub object that proposes merging one branch into another. Its review comments are attached to commit IDs and lines, and the IDs no longer exist on the branch. So the comments detach, and the diffs of closed pull requests break. A signature covers the commit object, the object is replaced, so the signature can't be carried over. The textbook's row says signatures are removed also on commits that predate the removed data. A rule that requires signed commits therefore rejects the rewritten history unless it is bypassed.

**[ANIMATION]** cards: question=Do_not_rewrite_... numbered=on cards=for_a_revoked_credential:when_the_provider_logs_show_no_use|a_public_repository:it_un-publishes_nothing|before_containment|in_your_working_clone:the_tool_prunes_reflogs_and_stashes|by_the_same_command_on_every_machine:identical_commands_can_produce_different_IDs title=Section_21B.22:_five_cases

**When not.** Section 21B.22 lists five cases. Don't rewrite for a credential that is revoked and whose provider logs show no use: record the decision and stop. Don't rewrite a public repository in the belief that it un-publishes anything. Don't rewrite before containment. Don't rewrite in your working clone, because the tool prunes reflogs and stashes, the work you set aside without committing. And don't have each colleague run the same command: identical commands can produce different IDs.

**[ON SCREEN]** Outdated advice.

Older guides use `git filter-branch` or the BFG Repo-Cleaner. Git's own manual says of `git filter-branch` that its "use is not recommended" and points to git-filter-repo. GitHub's current page documents git-filter-repo only. Keep that in mind for the demonstration, because the demonstration uses `git filter-branch`, for one reason only: it ships with Git, and the lab installs nothing. It isn't the recommended tool. It's enough to show four mechanics that are the same whichever tool rewrites: descendants get new IDs, tags must be rewritten too, old objects remain until pruned, and the server keeps them after the push.

## MENTAL MODEL

A picture helps. The textbook's analogy is the recall of a printed book to remove one page. You can reprint every copy in your warehouse. Each reader's copy stays as it was until that reader exchanges it. The page numbers after the removed page all change. Every citation by page number now points at the wrong place. And one reader who lends an old copy to the library puts the page back on the shelf.

**[ANIMATION]** walk: columns=the_book_recall,the_rewrite rows=the_warehouse:the_cleanup_clone_and_the_server|the_readers'_copies:clones_and_forks|the_page_numbers:commit_IDs|the_citations:everything_that_stored_an_ID|the_reader_who_lends_an_old_copy:the_stale_clone_of_the_next_video mono=off

Map it. The warehouse is the cleanup clone and the server. The readers' copies are clones and forks. The page numbers are commit IDs. The citations are everything that stored an ID: issue comments, release notes, experiment records, deployment manifests. The reader who lends the old copy is the stale clone of the next video.

**[ANIMATION]** end

Where the analogy breaks: a reprinted book has no memory of the old edition, and a Git repository does. After the rewrite the old objects are still in the object database, unreachable, until something prunes them. The warehouse still has the old copies in the back room.

**[ANIMATION]** stores: boxes=*the_cleanup_clone:where_the_filter_runs|the_server|a_colleague's_clone rows=1:A:new_commits_are_written@hl|2:A:refs_are_moved_to_them|3:A:old_objects_are_deleted,_separately|4:B:nothing_deleted_here@dim|4:C:nothing_deleted_here@dim title=Three_separate_things,_per_repository

So the model to carry is this. A rewrite does three separate things, and only the first one is done by the filter: it writes new commits. Then refs are moved to them. Then, separately and deliberately, old objects are deleted. Each of the three happens per repository. Nothing you do in one repository deletes anything in another.

## DIAGRAM

**[ANIMATION]** graph: dfd59fd-0c55276-6388058-987a49d-0805fd8-64b9b89-b509fe3-d4b8762 main; b509fe3-7fae871 feature/streaming; 987a49d tag:v0.1.0; 64b9b89 tag:v0.2.0; HEAD=none; note:0805fd8:.env_added; name:before; title:before => + range:dfd59fd,0c55276,6388058,987a49d:shared,_unchanged; name:shared => + 987a49d-0ac4257-66a99cc-51e2d95-c8ce738; 51e2d95-ba9f0e0; note:0ac4257:no_.env; name:replaced; title:after; say:Replaced:_everything_from_the_first_changed_commit_on => + c8ce738 main; 66a99cc tag:v0.2.0; ba9f0e0 feature/streaming; ghost:0805fd8,64b9b89,b509fe3,d4b8762,7fae871; name:after => + title:server.git,_after_the_forced_push; say:No_ref_leads_to_the_five_old_commits._They_are_still_there; name:server id=rw

**[DIAGRAM]** Build the "before" line first, left to right: eight commits on `main`. Mark the fifth, where `.env` was added. Hang `v0.1.0` below the commit before it and `v0.2.0` above the commit after it. Branch `feature/streaming` off the seventh commit.

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

**[ANIMATION]** step: rw.before

Watch the "before" line turn into the "after" line. Eight commits on `main`, the fifth is where `.env` was added, two tags, and `feature/streaming`.

**[ANIMATION]** step: rw.shared

In the "after" line, the first four commits are the same objects: same IDs, drawn in the same place.

**[ANIMATION]** step: rw.replaced

From the fifth commit on, every ID is different.

Quick quiz. The sixth, seventh and eighth commits got new IDs as well, although nobody edited the changes they make. Which field of a commit makes that unavoidable: A, the message, B, the parent, or C, the author? Your answer?

**[PAUSE]**

B, the parent. Each commit records its parent's ID, and the parent was replaced. The words on the picture are the sentence to remember: shared and unchanged up to the commit before the leak, replaced from the first changed commit on.

**[ANIMATION]** step: rw.after

`v0.1.0` stays where it was. `v0.2.0` has to move, and so does `feature/streaming`.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/rewrite-mechanics`. The caption bar shows `labs/ch21b/rewrite-mechanics.sh`. The secret in this repository is a dummy string that says so in its own text. The IDs on screen equal the IDs in the book, because the replay runs on the fixed lab clock.

Into the lab. The secret in this repository is a dummy string, and it says so in its own text.

**Step 1: a fresh mirror clone.** 🟢 SAFE: a clone creates a new repository. A mirror clone has every ref of the server as a local ref, which is what a rewrite needs.

```bash
git clone -q --mirror server.git cleanup.git
cd cleanup.git
git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"
git log --oneline main
first=$(git log --format=%h --diff-filter=A main -- .env); echo $first
```

Make your prediction. How many refs will the listing show, and of which kinds? Say it out loud.

**[PAUSE]**

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

Four refs: two branches and two tags. The tags are of type `tag`, so they're annotated tags, stored as objects of their own. Now the last line: the commit that added `.env` is `0805fd8`, "Add staging settings". Everything from that commit on is affected. The four commits below it are not.

Try it now, for thirty seconds. In the lab shell, or in any repository you have, type `git for-each-ref`. It only reads. Each line is one ref and the object it points at. Count the tags. I'll wait.

**[PAUSE]**

Each line you saw is a ref, and any ref that still points into old history keeps it alive. So a rewrite has to cover them all, tags included. Now watch what happens when the tags are forgotten.

**Step 2: the mistake first. Rewrite the branches and forget the tags.** 🔴 DANGEROUS. Before running a history filter, the five answers. What it changes: every affected commit and all descendants, on every ref it is given. What it can destroy: signatures, and with a wrong path argument, files you meant to keep. How to preview: git-filter-repo has `--dry-run`. And you run in a fresh clone. How to recover: the untouched server and other clones, until you push. When it is appropriate: for data that stays harmful after rotation. For an unpushed mistake on a private branch a rebase is the smaller tool.

```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' -- --branches > ../filter-1.log 2>&1
grep -v 'seconds passed' ../filter-1.log
git grep -l DUMMY-KEY $(git rev-list --branches) | wc -l
git grep -l DUMMY-KEY $(git rev-list --all) | cut -c1-9,41-
git tag --contains $first
```

Predict. After the branches are rewritten, does a scan over all refs still find the key? Yes or no, out loud.

**[PAUSE]**

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

Hold on the two counts. Over the branches: zero. Over all refs: five snapshots that contain the key. So the answer was yes. The last command says why: the tag `v0.2.0` contains the first affected commit.

**[ANIMATION]** graph: dfd59fd-0c55276-6388058-987a49d-0805fd8-64b9b89-b509fe3-d4b8762; b509fe3-7fae871; 987a49d-0ac4257-66a99cc-51e2d95-c8ce738 main; 51e2d95-ba9f0e0 feature/streaming; 987a49d tag:v0.1.0; 64b9b89 tag:v0.2.0; HEAD=none; note:d4b8762:refs/original/; note:7fae871:refs/original/; note:0805fd8:.env; title:cleanup.git; say:The_tag_still_points_at_the_old_commit_64b9b89; name:attempt => + 66a99cc tag:v0.2.0; drop:d4b8762,7fae871; note:0805fd8:.env; note:64b9b89:refs/original/; reflog:b509fe3,d4b8762,7fae871; say:Every_ref_is_moved._The_old_objects_are_still_there; name:allrefs => + gone:0805fd8,64b9b89,b509fe3,d4b8762,7fae871; drop:64b9b89,0805fd8; say:Pruned_in_this_clone_only; cmd:!git_gc_--prune=now; name:pruned id=att at_attempt=12

**[ANIMATION]** step: att.attempt

The tag points at the old commit `64b9b89`, and a tag keeps its commit and all of that commit's ancestors alive. Anyone who fetches the tag fetches the secret. One more detail from the textbook: `--all` also includes the backup refs that `filter-branch` wrote under `refs/original/`.

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

Predict again. Of the eight commits on `main`, how many have a new ID? Say it out loud.

**[PAUSE]**

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

Four. The four commits below the leak are byte for byte the same objects. This table is what git-filter-repo writes to `commit-map`. In an incident, that file belongs in the incident record, so that old IDs can be translated.

**[ANIMATION]** walk: columns=old_ID,its_tree,its_parent,new_ID rows=0805fd8:.env_removed:987a49d,_the_same:0ac4257|64b9b89:.env_removed:0ac4257,_new:66a99cc|b509fe3:.env_removed:66a99cc,_new:51e2d95|d4b8762:.env_removed:51e2d95,_new:c8ce738 marks=1.2:hl,2.2:hl,3.2:hl,4.2:hl,2.3:hl,3.3:hl,4.3:hl,1.3:dim last=new_ID title=Why_each_ID_changed id=why at_1=15

**[ANIMATION]** step: why.1

Now the reasons. `0805fd8` became `0ac4257` because its tree changed.

**[ANIMATION]** step: why.4

The three above it changed for two reasons. Every one of their snapshots held `.env` too, so their trees changed. And each records its parent's ID, and the parent changed. That second reason is enough by itself.

**[ANIMATION]** step: att.allrefs

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

Three deliberate steps: delete the backup refs, expire the reflogs, prune. Now `git cat-file -t` fails with "Not a valid object name", the scan prints zero, and `git fsck` prints nothing.

**[ANIMATION]** step: att.pruned

git-filter-repo performs this pruning for you at the end of its run, which is why it insists on a fresh clone.

**[ANIMATION]** end

**Step 7: the forced push.** 🔴 DANGEROUS. The five answers before the command is run. What it changes: `git push --force --mirror` sets every ref on the remote to the local value and deletes those the clone lacks. What it can destroy: branches and tags that exist only on the remote. A branch that a colleague pushed after you cloned is removed by your push. That's the mechanical reason for the freeze. Preview: `git push --dry-run --force --mirror origin`. Recovery: another clone that still has the old refs. On GitHub, the instruments of Chapter 13. When appropriate: once, after a freeze, at the end of a verified rewrite. Every other force push uses `--force-with-lease`.

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

Three forced updates, each with a plus sign: two branches and the tag `v0.2.0`. `v0.1.0` isn't listed, because it didn't change.

**Step 8: what the server holds now.** Here's the question from the opening. Predict before running: after this push, can the server still print the key? Yes or no, out loud.

**[PAUSE]**

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

This is the output the whole video was built for, and it closes the question from the opening. No ref on the server reaches the secret. The scan over all refs is clean. And `git show` on the server still prints the key, from a commit that `git fsck` lists as unreachable, with four others.

**[ANIMATION]** step: rw.server

Unreachable means that no ref leads to it any more. A bare repository of your own can be pruned with `git gc --prune=now`. On GitHub you can't run that. Video 168 says who can.

**[ON SCREEN]** The state table of section 21B.17.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| history rewrite in the cleanup clone | rewritten to the new tip (none in a mirror clone) | rewritten | unchanged (still names the branch) | moved to the new tip | every affected branch and tag moved; backup refs or `filter-repo/` metadata written; old objects kept until pruned | unchanged | unchanged |
| `git reflog expire --expire=now --all` then `git gc --prune=now` | unchanged | unchanged | unchanged | unchanged | all reflog entries and all unreachable objects deleted | unchanged | unchanged |
| `git push --force --mirror origin` | unchanged | unchanged | unchanged | unchanged | unchanged | every ref set to the local value; refs missing locally are **deleted**; old objects stay as unreachable | branch and tag refs move; pull request refs are refused; cached views and old objects stay until Support acts |

Read the last two columns of the first two rows: unchanged, unchanged. Nothing you did in the cleanup clone touched the remote until the push, and the push moved refs only.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Rewriting the branches and forgetting the tags.** Root cause: a tag is a ref, and any ref that still points into the old history keeps the old commits and all their ancestors reachable and fetchable.
2. **Declaring the secret removed after the force push.** Root cause: a force push moves refs; the old objects stay on the server as unreachable objects, and in every other clone and fork as ordinary history.
3. **Rewriting in the working clone.** Root cause: the tool finishes by expiring reflogs and pruning, which destroys the local safety net, stashes included.
4. **Taking the mirror clone before the freeze.** Root cause: `git push --force --mirror` deletes every remote ref that the cleanup clone does not have, so a branch pushed in between is removed.
5. **Rewriting before revoking.** Root cause: the damage happens at the issuer, where the key is accepted, and no change to any repository makes a copied key stop working.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML platform team finds that a file with customer support transcripts was committed to the evaluation repository four months ago. This isn't a credential. Nothing can be rotated, so the data stays harmful, and the textbook's criterion for a rewrite is met.

**[ANIMATION]** gates: packet=the_plan gates=a_freeze:done:-:from_a_stated_time|rules_on_force_pushes_and_tags_switched_off:done:-:with_an_owner_for_switching_them_back_on|a_fresh_clone:done:-:on_one_machine|the_verification_commands:done|the_count_of_affected_pull_requests:done:-:for_the_Support_request|the_instruction_to_colleagues:done:-:about_their_clones title=The_operation_around_the_command

The lead writes the plan before anyone types a command: a freeze from a stated time, the rules that block force pushes and tag updates switched off for the duration and an owner for switching them back on, a fresh clone on one machine, the verification commands, the count of affected pull requests for the Support request, and the instruction to colleagues about their clones.

**[ANIMATION]** end

Then comes the cost that is specific to an ML team. Every experiment record, model card and deployment manifest that stored a commit ID from the last four months now points at a commit that no longer exists on the remote. The team doesn't try to edit all of those records. It stores git-filter-repo's `commit-map` file in the incident record, so that anyone who holds an old ID can translate it. And because the repository required signed commits, the lead plans the bypass for the rewritten history in advance, since the signatures are gone.

## PRACTICE EXERCISE

Your turn. Do Lab 31.1, "The tabletop: a committed secret, from report to prevention", in [`lab-manual/m31-secret-leak-response.md`](../../lab-manual/m31-secret-leak-response.md). It runs entirely in the lab shell, with a bare repository as the server, three clones and a dummy secret.

Before you run the rewrite in the lab, write down three predictions: which refs will be reported as rewritten and which as unchanged, how many of the commits on `main` will have new IDs, and what `git show` of the first affected commit will print on the server after the forced push. Then run it and compare. The lab's questions have no answers in the lab file. Attempt them before you open the answers.

When that is done, the challenge is Exercise 31.5, Level 4, "How far did it get?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q336: "When is a history rewrite the wrong response to a leaked secret? What does it cost?"

**[PAUSE]**

Answer it out loud before you open the answers file. A strong answer does four things. It starts with the layer where the damage happens, the issuer, and says what revocation achieves that no repository operation can. It gives the criterion for when a rewrite is warranted at all, with examples of data that can't be rotated. It names the costs concretely: what happens to clones, to recorded commit IDs, to signatures, to open pull requests, and what the rewrite can't recall. And it ends with a decision that is written down with its reason. An answer that describes only the filter command has answered a different question.

## RECAP

**[ANIMATION]** say: Shared_up_to_987a49d,_replaced_from_0ac4257_on

Let's land this. You should now be able to say these sentences, in your own words.

- A whole-history rewrite replaces the first affected commit and every descendant with new commits that have new IDs; the ancestors of the first affected commit are untouched.
- git-filter-repo is a separate program; it wants a fresh clone, records a commit map, removes signatures, and prunes at the end.
- All refs have to be rewritten and force-pushed, tags included, because any ref into the old history keeps it alive.
- A rewrite adds objects and moves refs; old objects remain until they are pruned, in every repository separately, and the server keeps them after the push.
- A rewrite is for data that stays harmful after rotation; for a key that was revoked within the hour it costs more than it buys.

## HOMEWORK

Read sections 21B.16 and 21B.17 of the textbook. Then do Exercise 31.4, Level 3, "Review this runbook", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Today you followed a rewrite from the fresh clone to the forced push, and you saw what it leaves behind. Run the lab once before you go on. Next time, a colleague who never read the freeze message pulls and pushes: the stale clone that pushes the secret back, the GitHub side of a rewrite, and the controls that limit blast radius. Until then, look at the state first and type second. See you in the next one.

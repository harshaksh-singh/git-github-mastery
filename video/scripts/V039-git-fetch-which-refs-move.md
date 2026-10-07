# V039: git fetch: which refs move

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 20
- **Prerequisites:** V038
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), section 12.4
- **Demo scripts:** `labs/ch12/fetch-anatomy.sh`, `labs/ch12/fetch-tags.sh`

## HOOK

**[ON SCREEN]** `Your branch is up to date with 'origin/main'.`

A release engineer tags from a laptop whose status said "up to date". The last fetch was two days old, so the tag misses yesterday's hotfix. The build goes out without the fix.

Git didn't lie. The sentence on screen compares two refs, and both of them are on the laptop. In the next twenty minutes you learn exactly which refs a fetch moves, which it never touches, and how to ask a server a question without changing anything.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you saw that a remote is configuration that stands for another repository, plus a set of remote-tracking branches such as `origin/main`, and that those branches record the last-known state of the server. This video is about the one command whose whole job is to refresh that record: `git fetch`.

Fetch is the safest of the transfer commands and the most misunderstood. Engineers avoid it because they think it might change their work, and they trust `git status` because they think it asks the server. Both beliefs are wrong, and they are wrong in opposite directions.

You will watch one fetch in detail: before, the server's answer, the fetch itself, and after. Then two variations, fetching one branch and fetching from a URL. Then tags, which follow their own rule.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- State exactly what `git fetch` writes and what it never touches.
- Explain why "up to date with origin/main" describes the last fetch.
- Ask the server for its refs without fetching.
- Inspect what a fetch brought before integrating it.

## CONCEPT

**[ANIMATION]** remotes: with Asha branch=main ids=95671d3,510ee94,ef22149 note=the_bare_server title=What_git_fetch_moves steps=setup,teammate-push,fetch,pull say_fetch=fetch_downloads_ef22149:_origin/main_moves,_your_main_does_not cmd_pull=git_merge_--ff-only_origin/main say_pull=Integration_is_a_separate_step:_now_your_main_moves

**[ANIMATION]** step: teammate-push

Here's today's situation. You cloned when `main` was at `510ee94`. Since then Asha has published `ef22149` on the server, and your clone hasn't asked.

**[ANIMATION]** step: fetch

In one sentence: `git fetch` 🟢 SAFE asks a remote where its refs point, downloads the objects you lack, and moves your remote-tracking refs to match. It never moves a local branch, the index or the working tree.

Why does such a command exist as a separate step? Because looking and deciding are different acts. Fetch lets you see what the other repository has, in full, with every tool you already know, before you change one line of your own work.

**[ANIMATION]** flow: id=wire actors=your_Git,*origin msgs=1>2:where_do_your_refs_point?|2>1:main_is_at_ef22149|1>2:send_the_objects_I_lack|2>1:the_objects|1>1:origin/main_moves_to_ef22149:ok|1>1:followed_tags_are_created|1>1:FETCH__HEAD_is_rewritten|1>1:origin/HEAD,_if_it_is_missing title=One_git_fetch at_1=30 at_2=45 at_3=62 at_4=70 at_5=80

**[ANIMATION]** step: 5

Precisely. The command is `git fetch`, optionally a remote, optionally refspecs. A refspec, remember, is the rule that says which refs are copied, and under which names. The remote defaults to the upstream remote of the current branch, otherwise `origin`. Without a refspec on the command line, the configured `remote.<name>.fetch` values select the server's refs and say which local ref records each. For every selected ref Git downloads missing objects and updates the destination if the update is a fast-forward or the refspec begins with a plus sign.

**[ANIMATION]** step: 8

There are three extras. Tags that point into the fetched history are created. That's called tag following. `FETCH_HEAD` is rewritten. And a missing `origin/HEAD` is created.

**[ANIMATION]** end

Quick quiz. You have uncommitted edits in three files, and you run `git fetch`. What happens to them? A, nothing. B, they are overwritten. C, Git refuses to fetch. Your answer?

**[PAUSE]**

**[ON SCREEN]** The state table for `git fetch`.

```text
Working tree   Index       HEAD        Current branch ref   Other refs and files in .git             Remote      GitHub
------------   ---------   ---------   ------------------   --------------------------------------   ---------   ---------
unchanged      unchanged   unchanged   unchanged            remote-tracking refs and their reflogs;  unchanged   unchanged
                                                            followed tags; FETCH_HEAD; origin/HEAD
                                                            if missing; new objects
```

A, nothing. Inside `.git`, a fetch writes new objects. The refs under `refs/remotes/<remote>/` and their reflogs. Possibly refs under `refs/tags/`. And `FETCH_HEAD`. And here is the list to memorize, the things it does not touch: `refs/heads/*`, `HEAD`, and the `index`.

**[ANIMATION]** walk: id=ask columns=command,opens_a_connection,changes_in_your_repository rows=git_status:no:nothing|git_ls-remote:yes:nothing|git_fetch:yes:remote-tracking_refs,_never_your_branch marks=1.2:bad,2.2:ok,3.2:ok title=Who_asks_the_server? at_1=15 at_2=50 at_3=85

**[ANIMATION]** step: 3

Now the other half. `git status` compares two local refs. It opens no connection. `git ls-remote` does open a connection: it asks the server for its refs and changes nothing in your repository.

**[ANIMATION]** end

When is a plain fetch not enough? When you expect it to update a tag you already have. A fetch creates tags that point into the history it fetched. It does not update a tag you already have. You will see the rejection and the forced update.

And the failure mode is the hook: acting on a remote-tracking ref of unknown age as if it were the server.

## MENTAL MODEL

**[ON SCREEN]** "A scout returns and you redraw the wall map."

A picture helps. The textbook's analogy: a scout returns and you redraw the wall map. The other team's flags are placed where the scout saw them. Your own flags stay where they are, and the map starts to age the moment it is drawn.

**[ANIMATION]** step: fetch

It breaks in one place: the scout also brings back a complete copy of everything the other team built, not only the positions. After a fetch you hold the commits themselves. You can log them, diff them, check them out, with no further network access.

Two consequences to carry around. A fetch cannot hurt your work, because your flags are not on its list. And no local command can tell you where the server is now. Only the scout can.

## DIAGRAM

**[ANIMATION]** fetch: [server] ...older-510ee94-ef22149 main; HEAD=none || [you] ...older-510ee94 main origin/main; HEAD=main => || [you] ...older-510ee94-ef22149 origin/main tag:v0.1.0; 510ee94 main; HEAD=main; cmd:git_fetch title=Before_and_after_git_fetch dx=330 at_state_1=12 at_state_2=30

**[DIAGRAM]** Two columns, before and after. On the left, draw the server with two commits and your repository with one, `main` and `origin/main` on the same commit. On the right, add the commit to your repository and move only the `origin/main` label and the tag.

```text
  before git fetch                                  after git fetch

  server   ...---510ee94---ef22149   main           server   unchanged

  you      ...---510ee94             main           you      ...---510ee94---ef22149
                 origin/main                                      main      origin/main
                                                                  (HEAD)    tag: v0.1.0
```

`main` and HEAD stayed on `510ee94`. Only `origin/main` moved. That gap between the two labels is what you inspect before you integrate.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/fetch-anatomy`. Asha has published a commit on `main`, a new branch and a tag. You have not fetched since you cloned.

**Step 1: the stale status.**

```bash
git status
git show-ref --abbrev
```

<!-- snippet: ch12/fetch-anatomy/01-stale-status -->
```text
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
$ git show-ref --abbrev
510ee94 refs/heads/main
510ee94 refs/remotes/origin/HEAD
510ee94 refs/remotes/origin/main
```
<!-- /snippet -->

Question for you: is your branch up to date? Say it out loud. I'll wait.

**[PAUSE]**

The honest answer is: up to date with what? `refs/heads/main` and `refs/remotes/origin/main` are both at `510ee94`. No connection was made. The sentence is true of your last fetch and says nothing about the server.

**Step 2: ask the server.**

```bash
git ls-remote origin
```

<!-- snippet: ch12/fetch-anatomy/02-ls-remote -->
```text
$ git ls-remote origin
ef22149d97a296904ccbf984cf520a1fc387e195	HEAD
698e2261b0e2c60654fc059c6016c8d743a05571	refs/heads/feature/reranker
ef22149d97a296904ccbf984cf520a1fc387e195	refs/heads/main
effd2621f6264b45f395c4ba776533482d6f466b	refs/tags/v0.1.0
ef22149d97a296904ccbf984cf520a1fc387e195	refs/tags/v0.1.0^{}
```
<!-- /snippet -->

One line per ref on the server. Its `main` starts with `ef22149`, not with `510ee94`. An annotated tag is a small object of its own, with its own ID, and the line ending in `^{}` is the commit that the annotated tag points to. `git ls-remote` accepts `--branches`, `--tags` and name patterns, and with `--exit-code` it fails when nothing matches, which is how a script should test whether a branch exists on a server.

**Step 3: fetch.** Predict the lines of output: how many refs, and what kind of update for each.

**[PAUSE]**

<!-- snippet: ch12/fetch-anatomy/03-fetch -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..ef22149  main             -> origin/main
 * [new branch]      feature/reranker -> origin/feature/reranker
 * [new tag]         v0.1.0           -> v0.1.0
$ cat .git/FETCH_HEAD
ef22149d97a296904ccbf984cf520a1fc387e195		branch 'main' of ../../server/support-bot
698e2261b0e2c60654fc059c6016c8d743a05571	not-for-merge	branch 'feature/reranker' of ../../server/support-bot
effd2621f6264b45f395c4ba776533482d6f466b	not-for-merge	tag 'v0.1.0' of ../../server/support-bot
```
<!-- /snippet -->

Three lines. `510ee94..ef22149  main -> origin/main` is a fast-forward of a remote-tracking branch, printed as a range that you can paste into `git log`. `* [new branch]` and `* [new tag]` are creations. The name after the arrow is always a ref of yours.

`FETCH_HEAD` holds one line per fetched ref: object ID, a marker, a description. Exactly one line is not marked `not-for-merge`: the upstream of the branch you are on. That line is what `git pull` integrates, in the next video.

**Step 4: what moved.** Predict `refs/heads/main`.

**[PAUSE]**

<!-- snippet: ch12/fetch-anatomy/04-after -->
```text
$ git show-ref --abbrev
510ee94 refs/heads/main
ef22149 refs/remotes/origin/HEAD
698e226 refs/remotes/origin/feature/reranker
ef22149 refs/remotes/origin/main
effd262 refs/tags/v0.1.0
$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
```
<!-- /snippet -->

`refs/heads/main` is still at `510ee94`. `git status`, still without any network access, now gives a different answer, "behind by 1 commit", because one of the two refs it compares has changed.

**Step 5: look before you decide.**

Try it now. Thirty seconds, on paper. Your `main` is at `510ee94` and `origin/main` is at `ef22149`. Write the `git log` command that lists exactly the commits the remote has and your branch lacks. Then say it out loud.

**[PAUSE]**

<!-- snippet: ch12/fetch-anatomy/05-graph -->
```text
$ git log --oneline --graph --decorate --all
* 698e226 (origin/feature/reranker) Add reranker stub
* ef22149 (tag: v0.1.0, origin/main, origin/HEAD) Implement retrieval
* 510ee94 (HEAD -> main) Add retrieval config
* 95671d3 Add retriever skeleton
* f56c1bb Add README
$ git log --oneline main..origin/main
ef22149 Implement retrieval
```
<!-- /snippet -->

The graph shows HEAD and `main` one commit below `origin/main`. And the answer: `git log main..origin/main` lists exactly the commits the remote has and your branch lacks. Two dots, with your branch on the left. This is the practical argument for fetching instead of pulling: you look first and decide second.

**Step 6: the record of what you observed.**

<!-- snippet: ch12/fetch-anatomy/06-reflog -->
```text
$ git reflog show origin/main
ef22149 refs/remotes/origin/main@{0}: fetch: fast-forward
$ git reflog show main
510ee94 main@{0}: clone: from $LAB/ch12/fetch-anatomy/server/support-bot.git
```
<!-- /snippet -->

Every remote-tracking ref has a reflog. Its entries are a history of what you observed on the server, and in plain Git it is the only such history, because the bare server keeps none. The reflog of the local branch shows that it has not moved since the clone.

**[ANIMATION]** step: remotes.pull

**Step 7: integrate, as a separate local step.** `git merge --ff-only` 🟡 CAUTION: it moves your branch.

<!-- snippet: ch12/fetch-anatomy/07-integrate -->
```text
$ git merge --ff-only origin/main
Updating 510ee94..ef22149
Fast-forward
 app/retriever.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

`## main...origin/main` with nothing in brackets means the two refs are equal.

**Step 8: one branch.** The server has moved again.

```bash
git fetch origin main
```

<!-- snippet: ch12/fetch-anatomy/08-fetch-one-branch -->
```text
$ git fetch origin main
From ../../server/support-bot
 * branch            main       -> FETCH_HEAD
   ef22149..3f226f1  main       -> origin/main
$ cat .git/FETCH_HEAD
3f226f11ffbe22690dad919d155901b0885028cc		branch 'main' of ../../server/support-bot
$ git status -sb
## main...origin/main [behind 1]
```
<!-- /snippet -->

With a branch named on the command line only that branch is fetched, and `FETCH_HEAD` has a single line. `origin/main` is updated as well, because the configured refspec says where `main` of `origin` is recorded.

**Step 9: from a URL.** Same repository, addressed by path instead of by name. Predict which refs move.

**[PAUSE]**

<!-- snippet: ch12/fetch-anatomy/09-fetch-url -->
```text
$ git fetch ../../server/support-bot.git feature/reranker
From ../../server/support-bot
 * branch            feature/reranker -> FETCH_HEAD
$ cat .git/FETCH_HEAD
698e2261b0e2c60654fc059c6016c8d743a05571		branch 'feature/reranker' of ../../server/support-bot
$ git log --oneline -1 FETCH_HEAD
698e226 Add reranker stub
```
<!-- /snippet -->

None. A fetch from a URL records its result in `FETCH_HEAD` and nowhere else, although the URL is the same repository as `origin`. Git knows remotes by name, not by URL. Use this form for a single look at somebody's branch.

**Step 10: nothing new.**

<!-- snippet: ch12/fetch-anatomy/10-quiet-fetch -->
```text
$ git fetch
$ git fetch --verbose
From ../../server/support-bot
 = [up to date]      main             -> origin/main
 = [up to date]      feature/reranker -> origin/feature/reranker
```
<!-- /snippet -->

A fetch that finds nothing new prints nothing. With `--verbose` it lists each ref as up to date. Silence from a fetch is information: the scout went and the map did not change.

**[ANIMATION]** remotes: [server] 510ee94-99b6430 main atag:v0.1.0#f858aef; 99b6430-e4e2561 tag:experiment/rejected-1; HEAD=none || [you] 510ee94 main origin/main atag:v0.1.0#5ff339b; HEAD=main title=A_tag_that_was_moved_on_the_server id=tags

**Tags.** `labs/run ch12/fetch-tags`. A tag is a name for a commit that is not expected to move. On the server, `v0.1.0` has been moved all the same, by a forced tag push, and a second tag sits on a commit that is on no branch.

<!-- snippet: ch12/fetch-tags/01-moved-tag -->
```text
$ git ls-remote --tags origin
e4e2561179ddf88e121ea1ebbb2485416f92363c	refs/tags/experiment/rejected-1
f858aefbb840dff2a665a6adbbaf8103bb645238	refs/tags/v0.1.0
99b643016420ca155f7432cf4555c1991c7679a5	refs/tags/v0.1.0^{}
$ git fetch
From ../../server/support-bot
   510ee94..99b6430  main       -> origin/main
$ git show-ref --abbrev --tags
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

The plain fetch moved `origin/main` and brought neither tag. Your `v0.1.0` already exists, and the other tag does not point into fetched history. Now ask for every tag. Predict what happens to the one that moved.

**[PAUSE]**

<!-- snippet: ch12/fetch-tags/02-fetch-tags -->
```text
$ git fetch --tags
From ../../server/support-bot
 * [new tag] experiment/rejected-1 -> experiment/rejected-1
 ! [rejected] v0.1.0                -> v0.1.0  (would clobber existing tag)
[exit status: 1]
$ git show-ref --abbrev --tags
e4e2561 refs/tags/experiment/rejected-1
5ff339b refs/tags/v0.1.0
```
<!-- /snippet -->

The new one arrives. The moved one is rejected: "would clobber existing tag", exit status 1. Only `git fetch --tags --force` 🟡 CAUTION replaces it.

<!-- snippet: ch12/fetch-tags/03-force -->
```text
$ git fetch --tags --force
From ../../server/support-bot
 t [tag update]      v0.1.0     -> v0.1.0
$ git show-ref --abbrev --tags
e4e2561 refs/tags/experiment/rejected-1
f858aef refs/tags/v0.1.0
```
<!-- /snippet -->

Until someone forces, your `v0.1.0` and the server's are different commits under one name, and a build "by tag" gives different results on different machines. That is why moving a published tag is a release incident and not a convenience.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause. Then the root-cause box of section 12.4.

1. **Believing "up to date with 'origin/main'" means "up to date with the server".** Root cause: `git status` compares two local refs and opens no connection; `origin/main` is a record of your last fetch.
2. **Avoiding `git fetch` on a dirty working tree.** Root cause: none in Git; fetch writes remote-tracking refs, tags, `FETCH_HEAD` and objects, and never `refs/heads/*`, HEAD or the index.
3. **Fetching from a URL and expecting `origin/main` to move.** Root cause: Git knows remotes by name, so a URL fetch records its result only in `FETCH_HEAD`.
4. **Expecting a fetch to correct a tag that was moved on the server.** Root cause: a fetch does not update a tag you already have; `--tags` rejects it and only `--tags --force` replaces it.
5. **Scripts that compare against a remote-tracking ref of unknown age.** Root cause: the ref is as old as the last fetch in that clone; `git ls-remote` asks the server.

```text
Observed behavior : "Your branch is up to date with 'origin/main'", yet the server has newer commits.
Git state         : refs/heads/main and refs/remotes/origin/main name the same commit; the server's
                    refs/heads/main names a newer one.
Mechanism         : git status compares two local refs. It opens no connection.
Root cause        : origin/main is a record of your last fetch, not a view of the server.
Why Git does this : every command except the transfer commands works offline and instantly; a status
                    that needed the network would be slow, and useless on a plane.
Correct fix       : git fetch, then read the status again; or git ls-remote origin main to ask the
                    server without changing anything.
Prevention        : fetch before any decision that depends on the server (tagging, releasing, cutting
                    a hotfix branch). In scripts compare against git ls-remote, never against a
                    remote-tracking ref of unknown age.
```

And here is the root-cause box for the hook. The status compared two local refs, and `origin/main` was a record of the last fetch.

## PRODUCTION EXAMPLE

Now, out of the lab. Return to the release engineer from the hook. The tag missed yesterday's hotfix because the last fetch on that laptop was two days old.

**[ANIMATION]** flow: actors=the_release_script,your_clone,*the_server msgs=1>3:git_fetch|1>2:git_rev-parse_HEAD|1>3:git_ls-remote_origin_refs/heads/main|1>1:equal?_only_then_continue:ok boundary=2 zones=the_laptop,the_network mono=on title=A_release_script_that_asks_the_server at_1=45 at_2=65 at_3=78 at_4=86

**[ANIMATION]** step: 4

The textbook is direct about the control: it is not "be careful". It is a release script that begins with `git fetch` and refuses to continue unless `git rev-parse HEAD` equals the ID that `git ls-remote origin refs/heads/main` prints.

Notice the shape of that control. It does not trust a person to remember, and it does not trust a remote-tracking ref. It compares the commit being released with what the server reports at that moment. For a team that ships model-serving code, where a tag triggers an image build and a rollout, that comparison is the difference between a release and an incident.

## PRACTICE EXERCISE

Your turn. Do Exercise 7.2, Level 1, "fetch first, look, then integrate", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Predict in writing before you type:

- Before the fetch, what will `git status` say, and is that a statement about the server?
- After the fetch, which of these changed: `refs/heads/main`, `refs/remotes/origin/main`, HEAD, the index, the working tree?
- Which command lists the commits that arrived and are not yet in your branch?

The challenge is Exercise 7.9, Level 4, "a clone that has not talked to the server for a week", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q215: "State exactly what `git fetch` writes in your repository and what it never touches. Then name three things engineers expect a plain fetch to update that it does not."

**[PAUSE]**

Answer out loud first. A strong answer gives two lists, without hedging, in terms of refs and files in `.git`, not in terms of "it downloads changes". For the second half it picks three expectations from real work and for each one says what a plain fetch does do instead. The best answers explain one of the three from the refspec or from the tag rule, which shows the list was derived and not memorized.

## RECAP

**[ANIMATION]** remotes: with Asha branch=main ids=95671d3,510ee94,ef22149 note=the_bare_server title=What_git_fetch_moves steps=setup,teammate-push,fetch say_fetch=fetch_downloads_ef22149:_origin/main_moves,_your_main_does_not

Let's land this. You should now be able to say:

**[ANIMATION]** step: fetch

`git fetch` downloads objects and moves my remote-tracking refs. It writes `FETCH_HEAD`, follows tags into fetched history and creates a missing `origin/HEAD`. It never moves a local branch, HEAD, the index or the working tree.

**[ANIMATION]** step: ask.3

"Up to date with origin/main" is true of my last fetch, because `git status` compares two local refs. `git ls-remote` asks the server and changes nothing. After a fetch, `main..origin/main` shows what arrived, and integration is a separate local step.

## HOMEWORK

Read section 12.4 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Do Exercise 7.4, Level 2, "what the clone knows before and after a fetch", and Exercise 7.6, Level 2, "which refs does a fetch move?", both in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

Today you separated looking from deciding: a fetch redraws your map and leaves your own work alone. One `git fetch` would have shown that release laptop it was behind. Do Exercise 7.2 while this is fresh. Next time: upstream branches, and `git pull`. Until then, look at the state first and type second. See you in the next one.

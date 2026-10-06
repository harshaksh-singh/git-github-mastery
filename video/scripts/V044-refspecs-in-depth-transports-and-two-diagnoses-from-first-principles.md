# V044: Refspecs in depth, transports, and two diagnoses from first principles

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 26
- **Prerequisites:** V042, V043
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.12, 12.13 and 12.14
- **Demo scripts:** `labs/ch12/refspec-surgery.sh`, `labs/ch12/transports.sh`, `labs/ch12/transport-trace.sh`, `labs/ch12/diagnose.sh`

## HOOK

**[ON SCREEN]** `$ git push origin main` and below it `Everything up-to-date`.

The CTO's first question from this chapter: "The deploy job says the hotfix is not on the server. The engineer says they pushed it, and their terminal printed `Everything up-to-date`. Which one is wrong?"

Neither. The deploy job is right: the commit is not on the server. The engineer is right: they ran a push and Git reported success. And Git is right: "Everything up-to-date" is a true statement about the refspec that was pushed.

The whole incident is contained in one word of that command. By the end of this video you will find it in under a minute, with three questions and one request to the server. Keep your eye on that one word.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A ref is a name that points at a commit, such as a branch, and a remote is your name for another repository. This is the last content video of the remotes module, and it puts a name on something you have been using since the first one: the refspec. Every fetch and every push you have seen was driven by one. `git clone` wrote one into the configuration. `--single-branch` narrowed one. A bare `git push` built one from `push.default`.

Three parts. First, refspecs as a small language: read them, write them, widen a narrow clone, see what the plus sign does, exclude with a negative refspec. Second, transports in brief: what the URL selects, and which two programs talk to each other on the wire. Third, two diagnoses done from first principles, using only what this module has taught: "the push pushed nothing", and "my remote-tracking refs cannot be trusted".

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The four objectives.

After this video you can:

- Read and write a fetch refspec and a push refspec, including `+` and a negative refspec.
- Widen a narrow clone so that a missing branch becomes fetchable.
- Name the transports and trace which programs a fetch and a push run.
- Diagnose "the push pushed nothing" and "the branch exists on the server and this clone cannot see it".

## CONCEPT

**[ANIMATION]** walk: id=spec columns=command,source_(the_sending_side),destination_(the_receiving_side) rows=git_fetch:a_ref_name_on_the_remote:a_ref_name_of_yours|git_push:a_commit_expression_of_yours:a_ref_name_on_the_remote mono=off title=+source:destination at_1=12 at_2=55

**[ANIMATION]** step: header

**Refspecs.** In one sentence: a refspec, optional plus, source, colon, destination, is the only thing that decides which refs a fetch or a push touches: the source is on the sending side, the destination on the receiving side.

**[ANIMATION]** step: 2

Take that literally. For a fetch, the sender is the remote, so the source is a ref name over there and the destination is a ref name of yours. For a push, you are the sender, so the source is a commit expression of yours and the destination is a ref name over there.

**[ANIMATION]** cards: question=git_push_origin_HEAD~1:main cards=A:main_is_your_branch|B:main_is_the_server's_branch at_1=55 at_2=72

**[ANIMATION]** step: 2

Quick quiz. Take the push refspec `HEAD~1:main`. Which side does the word `main` name there? A, your branch. B, the server's branch. Your answer?

**[PAUSE]**

**[ANIMATION]** end

**[ON SCREEN]** The refspec table of section 12.12.

```text
Refspec                                       Where                  Meaning
--------------------------------------------  ---------------------  ----------------------------------------------
+refs/heads/*:refs/remotes/origin/*           fetch, configured      every branch to a remote-tracking ref, forced
+refs/heads/main:refs/remotes/origin/main     fetch, configured      one branch only
^refs/heads/dependabot/*                      fetch or push          negative: exclude what matches (Git 2.29+)
+refs/pull/*/head:refs/remotes/origin/pr/*    fetch, configured      map another namespace
pull/7/head:pr-7                              fetch, command line    one ref into a local branch
main                                          push                   refs/heads/main:refs/heads/main
HEAD~1:main                                   push                   any commit of yours to a branch of theirs
HEAD:refs/heads/review/x                      push                   create a branch under another name
:review/x                                     push                   delete
+main                                         push                   force this ref only
```

It's B. On a push, the destination is over there. Now three lines that deserve a comment. `main` alone, on a push, is shorthand for `refs/heads/main:refs/heads/main`: my `main` to their `main`. An empty source, colon then a name, is a deletion. And the plus sign means: allow this update even when it is not a fast-forward, a move to a descendant.

Why does the default fetch refspec carry the plus sign? Because a remote-tracking ref has to record the server as it is, rewritten or not.

**[ANIMATION]** match: id=rule header=remote.origin.fetch rules=+refs/heads/main:refs/remotes/origin/main paths=refs/heads/main:1|refs/heads/release/0.1: none_text=no_match:_nothing_is_created title=A_--single-branch_clone at_1=50 at_2=62

**[ANIMATION]** step: 2

When does a refspec hurt you? When it is narrower or wider than you think. A fetch refspec is configuration that silently shapes what a clone can see. A CI clone made with `--single-branch` has a refspec for one branch, which is why other branches are invisible there. And a mirror-style refspec pasted into an ordinary clone makes the next fetch overwrite local branches. Lab 7.7 ends with that.

**[ANIMATION]** end

**Transports.** The URL selects how the two Gits reach each other. What they say to each other is the same.

**[ON SCREEN]** The transport table of section 12.13.

```text
Transport   URL form                               Authentication                        Notes
---------   -------------------------------------  ------------------------------------  --------------------------------------------
local       /path/repo.git, ../repo.git            filesystem permissions                git clone hard-links or copies object files
file        file:///path/repo.git                  filesystem permissions                always the pack protocol
SSH         ssh://git@host/path, git@host:path     SSH keys                              runs Git's server programs on the host
HTTPS       https://host/path                      credentials supplied by a             the same conversation carried in HTTP
                                                   credential helper                     requests
git         git://host/path                        none                                  anyone who can reach the port can read
bundle      a file                                 none                                  offline; fetch and clone only
```

On the wire, the other side of a fetch is `git-upload-pack`, and the other side of a push is `git-receive-pack`. Over SSH the same two programs are started on the server.

**[ANIMATION]** cards: cards=three_things_called_main|a_few_commands_talk_to_the_server|a_push_transfers_the_refs_you_name:not_"my_work"|remote-tracking_refs_are_a_cache title=The_model_behind_both_diagnoses at_1=42 at_2=52 at_3=65 at_4=82

**[ANIMATION]** step: 4

**Diagnosis.** The method for both cases today is the model from the first video of this module: three things called `main`, and only a few commands that talk to the server. A push transfers the refs you name, not "my work". And remote-tracking refs are a cache.

## MENTAL MODEL

**[ON SCREEN]** "A refspec is a mail-forwarding rule that runs only when you fetch or push."

A picture helps. The textbook's analogy: a mail-forwarding rule. "Whatever is addressed to `refs/heads/X` over there, file it here as `refs/remotes/origin/X`."

It breaks because the rule runs only at the moment of a fetch or a push. Nothing is forwarded in between.

**[ANIMATION]** step: rule.2

Use the model as a diagnostic habit. When a clone "cannot see" a branch, the rule does not cover that name: print the rule. When a push "did nothing", the rule you typed selected a ref that had nothing new: read the rule you typed. In both cases the command to run first is not a fetch and not a push. It is the one that prints the refspec, or the one that asks the server what it has.

## DIAGRAM

**[DIAGRAM]** New diagram. Draw the refspec in the middle with its three parts labelled. Then trace one ref through it, from the server on the left to your clone on the right.

```text
                    +   refs/heads/*   :   refs/remotes/origin/*
                    |        |                    |
        force: allow a    source: names        destination: names
        non-fast-forward  on the SENDING side  on the RECEIVING side
        update

  fetch (the server sends):

    server                                               your clone
    refs/heads/release/0.1  --- * = release/0.1 --->     refs/remotes/origin/release/0.1

  with the narrow refspec  +refs/heads/main:refs/remotes/origin/main
    refs/heads/release/0.1  --- no match --->            (nothing is created)

  push (you send):   HEAD~1:main
    your commit HEAD~1      --------------------->       server  refs/heads/main
```

Read it from the top: a plus sign, a source, a destination. On a fetch the server sends, so `refs/heads/release/0.1` over there is filed as `refs/remotes/origin/release/0.1` here. With the narrow refspec, that name finds no match. On a push you send, so `HEAD~1` is yours and `main` is theirs.

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/refspec-surgery`.

**Part 1: a narrow clone.** A clone made with `--single-branch`, as a CI job makes it.

```bash
git config get --all remote.origin.fetch
git switch release/0.1
```

Predict the refspec, and the result of the switch. The branch exists on the server.

**[PAUSE]**

<!-- snippet: ch12/refspec-surgery/01-narrow-clone -->
```text
$ git clone --single-branch server/support-bot.git you/support-bot
Cloning into 'you/support-bot'...
done.
$ cd you/support-bot
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
$ git switch release/0.1
fatal: invalid reference: release/0.1
[exit status: 128]
```
<!-- /snippet -->

The refspec names `main` only. `git switch release/0.1` fails with "invalid reference". The clone has no ref of that name and its fetch rule would never create one.

Try it now. Thirty seconds, on paper. Write the fetch refspec that would let this clone see `release/0.1`. Then say it out loud.

**[PAUSE]**

<!-- snippet: ch12/refspec-surgery/02-widen -->
```text
$ git remote set-branches --add origin release/0.1
$ git config get --all remote.origin.fetch
+refs/heads/main:refs/remotes/origin/main
+refs/heads/release/0.1:refs/remotes/origin/release/0.1
$ git fetch
From ../../server/support-bot
 * [new branch]      release/0.1 -> origin/release/0.1
$ git remote set-branches origin "*"
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
$ git fetch
From ../../server/support-bot
 * [new branch]      dependabot/pip/requests-2.33 -> origin/dependabot/pip/requests-2.33
```
<!-- /snippet -->

The answer is the second refspec in the output: `+refs/heads/release/0.1:refs/remotes/origin/release/0.1`. `git remote set-branches --add` 🟡 CAUTION, it rewrites configuration, appends a refspec for one more branch, and `set-branches origin "*"` restores the wildcard. Each `git fetch` then brings exactly what the configured refspecs cover: first the release branch, then, with the wildcard, a dependabot branch you had never seen.

**Part 2: the plus sign.** Asha has rewritten the tip of `release/0.1` on the server. You remove the plus from your refspec and fetch. Predict.

**[PAUSE]**

<!-- snippet: ch12/refspec-surgery/03-plus -->
```text
# Asha has rewritten the tip of release/0.1 on the server. Your refspec, without its +:
$ git config set remote.origin.fetch "refs/heads/*:refs/remotes/origin/*"
$ git fetch
From ../../server/support-bot
 ! [rejected] release/0.1 -> origin/release/0.1  (non-fast-forward)
[exit status: 1]
$ git config set remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
$ git fetch
From ../../server/support-bot
 + d5379f1...6c2ddc6 release/0.1 -> origin/release/0.1  (forced update)
```
<!-- /snippet -->

`! [rejected] ... (non-fast-forward)`, on a fetch. Your picture of the server stays wrong. With the plus restored, the remote-tracking ref is forced: plus sign, three dots, "(forced update)".

One careful note from the textbook. The `git fetch` manual of 2.55 says updates outside `refs/heads/` and `refs/tags/` are accepted without the plus. This transcript shows that Git 2.55.0 rejects a non-fast-forward update of `refs/remotes/origin/release/0.1` without it. The run wins.

**Part 3: a negative refspec.**

<!-- snippet: ch12/refspec-surgery/04-negative -->
```text
$ git config set --append remote.origin.fetch "^refs/heads/dependabot/*"
$ git branch -r -d origin/dependabot/pip/requests-2.33
Deleted remote-tracking branch origin/dependabot/pip/requests-2.33 (was 510ee94).
$ git fetch
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/release/0.1
```
<!-- /snippet -->

A negative refspec excludes matching refs from later fetches. It does not delete a ref you already have, hence the `git branch -r -d`.

**Part 4: another namespace.**

<!-- snippet: ch12/refspec-surgery/05-pull-request-refs -->
```text
$ git ls-remote origin "refs/pull/*"
a3b0283892821a8f9fc95bda5760237390817915	refs/pull/7/head
$ git fetch origin pull/7/head:pr-7
From ../../server/support-bot
 * [new ref]         refs/pull/7/head -> pr-7
$ git config set --append remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
$ git fetch
From ../../server/support-bot
 * [new ref]         refs/pull/7/head -> origin/pr/7
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/dependabot/*
+refs/pull/*/head:refs/remotes/origin/pr/*
```
<!-- /snippet -->

Refs outside `refs/heads/` are invisible to the default refspec. Name one on the command line to fetch it into a local branch, or map the namespace permanently. The last command shows the three configured lines: the wildcard, the exclusion, and the mapping.

**[ON SCREEN]** Layer label: GitHub.

`refs/pull/<number>/head` is how GitHub exposes the head commit of every pull request. Its documentation gives `git fetch origin pull/ID/head:BRANCH_NAME` and states that the namespace is read-only: a push to it is answered with a `remote rejected` line saying "deny updating a hidden ref". `gh pr checkout <number>` wraps the fetch. Described from the documentation. The lab server here only imitates the ref.

**Part 5: push refspecs.** Two commits on `main`. `git push` 🟡.

<!-- snippet: ch12/refspec-surgery/06-push-refspecs -->
```text
# Two commits made on main: "Start the runbook", then "Add on-call notes".
$ git push origin HEAD~1:main
To ../../server/support-bot.git
   510ee94..73bb3c8  HEAD~1 -> main
$ git push origin HEAD:refs/heads/review/oncall-notes
To ../../server/support-bot.git
 * [new branch]      HEAD -> review/oncall-notes
$ git push origin :review/oncall-notes
To ../../server/support-bot.git
 - [deleted]         review/oncall-notes
$ git status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

Three push refspecs. Publish everything except your newest commit. Create a branch under a different name. And delete it, which is 🔴 as every deletion on a server. Status then shows the one commit that stayed local.

**Part 6: transports.** `labs/run ch12/transports`.

<!-- snippet: ch12/transports/01-url-forms -->
```text
# One scheme per URL, in the order given:
$ git url-parse -c scheme https://github.com/acme/support-bot.git git@github.com:acme/support-bot.git ssh://git@github.com/acme/support-bot.git file:///srv/git/support-bot.git
https
ssh
ssh
file
$ git url-parse -c host git@github.com:acme/support-bot.git
github.com
$ git url-parse -c path git@github.com:acme/support-bot.git
/acme/support-bot.git
$ git url-parse -c scheme ../../server/support-bot.git
fatal: '../../server/support-bot.git' is not a URL; if you meant a local repository, use a 'file://' URL with an absolute path
[exit status: 128]
```
<!-- /snippet -->

`git url-parse`, Git 2.55 or later, shows how Git reads a URL. The form `git@github.com:acme/support-bot.git` is SSH. A plain path is not a URL at all: it names a local repository.

`labs/run ch12/transport-trace`.

<!-- snippet: ch12/transport-trace/03-programs -->
```text
# Which program does Git start for the other side of the conversation?
$ GIT_TRACE=1 git fetch 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1
unset GIT_PREFIX; GIT_PROTOCOL=version=2 'git-upload-pack '\''../../server/support-bot.git'\'''
$ GIT_TRACE=1 git push 2>&1 | sed -n 's/.*trace: run_command: //p' | head -1
unset GIT_PREFIX; 'git-receive-pack '\''../../server/support-bot.git'\'''
```
<!-- /snippet -->

`git-upload-pack` for a fetch, `git-receive-pack` for a push.

<!-- snippet: ch12/transport-trace/01-fetch -->
```text
$ GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\(fetch[<>]\)/\1/p'
fetch< version 2
fetch< agent=git/2.55.0-Darwin
fetch< ls-refs=unborn
fetch< fetch=shallow wait-for-done
fetch< server-option
fetch< object-format=sha1
fetch< 0000
fetch> command=ls-refs
fetch> agent=git/2.55.0-Darwin
fetch> object-format=sha1
fetch> 0001
fetch> peel
fetch> symrefs
fetch> unborn
fetch> ref-prefix refs/heads/
fetch> ref-prefix refs/heads/main
fetch> ref-prefix refs/tags/
fetch> ref-prefix HEAD
fetch> 0000
fetch< 719650da56c2910ce851d3c0f47ec270ebb88945 HEAD symref-target:refs/heads/main
fetch< 719650da56c2910ce851d3c0f47ec270ebb88945 refs/heads/main
fetch< 0000
fetch> command=fetch
fetch> agent=git/2.55.0-Darwin
fetch> object-format=sha1
fetch> 0001
fetch> thin-pack
fetch> no-progress
fetch> include-tag
fetch> ofs-delta
fetch> want 719650da56c2910ce851d3c0f47ec270ebb88945
fetch> have 510ee948fb6354959cf03862f0ebe47c58eb2a74
fetch> have 95671d3baba80df6b53e79e6583c1a6e01fdf451
fetch> have f56c1bb279a37dc704979733d4314bd9c1e2893d
fetch> 0000
fetch< acknowledgments
fetch< ACK 510ee948fb6354959cf03862f0ebe47c58eb2a74
fetch< ready
fetch< 0001
fetch< packfile
```
<!-- /snippet -->

`GIT_TRACE_PACKET=1` prints the conversation. `fetch<` is received, and `fetch>` is sent. The server announces protocol version 2 and its capabilities. The client asks for refs with `ls-refs`, limited by `ref-prefix` lines derived from your refspecs, so a server with very many refs lists only those you can use. Then `want` names what you need and `have` what you already hold, and the server answers with a packfile of the difference, one file that holds the missing objects.

<!-- snippet: ch12/transport-trace/02-push -->
```text
# One local commit, already rebased onto the fetched origin/main:
$ GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\(push[<>]\)/\1/p' | cut -c1-110
push< 719650da56c2910ce851d3c0f47ec270ebb88945 refs/heads/main\0report-status report-status-v2 delete-refs sid
push< 0000
push> 719650da56c2910ce851d3c0f47ec270ebb88945 b109fc2446651be551de03e7834e6db8804e1cd1 refs/heads/main\0 repo
push> 0000
push< unpack ok
push< ok refs/heads/main
push< 0000
```
<!-- /snippet -->

A push is shorter: the advertisement, one "old, new, ref" command, the pack, and the report `unpack ok`, `ok refs/heads/main`.

Back to the transports demo for the last transport.

<!-- snippet: ch12/transports/02-bundle-create -->
```text
$ git bundle create ../../support-bot.bundle HEAD --branches
$ git bundle verify ../../support-bot.bundle
../../support-bot.bundle is okay
The bundle contains these 3 refs:
510ee948fb6354959cf03862f0ebe47c58eb2a74 HEAD
e553023017ca8545817a0931e13090569b6fe0c4 refs/heads/feature/eval-harness
510ee948fb6354959cf03862f0ebe47c58eb2a74 refs/heads/main
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

<!-- snippet: ch12/transports/03-bundle-clone -->
```text
$ cd ../..
$ git clone support-bot.bundle airgap/support-bot
Cloning into 'airgap/support-bot'...
$ git -C airgap/support-bot branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/feature/eval-harness
  remotes/origin/main
$ git -C airgap/support-bot remote -v
origin	$LAB/ch12/transports/support-bot.bundle (fetch)
origin	$LAB/ch12/transports/support-bot.bundle (push)
```
<!-- /snippet -->

A bundle is a file that plays the part of a remote. You can clone or fetch from it. You cannot push to it.

**Part 7: "the commit exists locally but not on the server".** `labs/run ch12/diagnose`.

<!-- snippet: ch12/diagnose/01-the-push-that-pushed-nothing -->
```text
$ git log --oneline -1
c19ab53 Set request timeout
$ git push origin main
Everything up-to-date
```
<!-- /snippet -->

That is the hook. Try it now, thirty seconds, on paper: before the next snippet, write down the three questions you would ask. I'll wait.

**[PAUSE]**

<!-- snippet: ch12/diagnose/02-where-is-the-commit -->
```text
$ git branch -a --contains HEAD
* hotfix/timeout
$ git status -sb
## hotfix/timeout
$ git log --oneline --branches --not --remotes
c19ab53 Set request timeout
```
<!-- /snippet -->

Question one, which branches contain the commit: one local branch, `hotfix/timeout`, and no remote-tracking branch. Question two, does that branch have an upstream: `## hotfix/timeout` with nothing after it means no. Question three, which commits has no remote-tracking ref ever seen: `git log --branches --not --remotes` lists `c19ab53`.

<!-- snippet: ch12/diagnose/03-ask-the-server -->
```text
$ git rev-parse HEAD
c19ab53ef3dba868f5f8b8c60d19a9687069f366
$ git ls-remote origin
510ee948fb6354959cf03862f0ebe47c58eb2a74	HEAD
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
```
<!-- /snippet -->

And the server, asked directly, has no ref at that ID.

**[ANIMATION]** graph: 95671d3-510ee94 main origin/main; 510ee94-c19ab53 hotfix/timeout; HEAD=hotfix/timeout => 95671d3-510ee94 main origin/main; 510ee94-c19ab53 hotfix/timeout origin/hotfix/timeout; HEAD=hotfix/timeout title=Where_the_commit_is id=where

**[ANIMATION]** step: state-1

Here's the whole incident in one picture, with its branch names. `main` and `origin/main` sit on `510ee94`. The hotfix, `c19ab53`, is on `hotfix/timeout`, and nowhere else. So `git push origin main` had nothing to send. The one word was `main`.

**[ON SCREEN]** The root-cause box of section 12.14.

```text
Observed behavior : git push printed "Everything up-to-date"; the deploy job cannot find the commit.
Git state         : HEAD is on hotfix/timeout, which has no upstream. The commit is on that branch only.
                    main equals origin/main.
Mechanism         : "git push origin main" is a refspec: send my main to their main. There was nothing
                    to send.
Root cause        : the command named a branch that does not hold the commit. A push transfers the
                    refs you name, not "my work".
Why Git does this : an explicit refspec is obeyed literally; Git has no idea which commit you care about.
Correct fix       : git push -u origin hotfix/timeout, then merge it by the team's process.
Prevention        : read the last lines of push output (<source> -> <destination>); verify with
                    git branch -a --contains <commit>; let deploy scripts verify with git ls-remote.
```

And the root-cause box for the hook. Read its prevention line: the last lines of push output name the source and the destination.

<!-- snippet: ch12/diagnose/04-fix -->
```text
$ git push -u origin hotfix/timeout
To ../../server/support-bot.git
 * [new branch]      hotfix/timeout -> hotfix/timeout
branch 'hotfix/timeout' set up to track 'origin/hotfix/timeout'.
$ git branch -a --contains HEAD
* hotfix/timeout
  remotes/origin/hotfix/timeout
$ git log --oneline --branches --not --remotes
```
<!-- /snippet -->

**[ANIMATION]** step: where.state-2

After the fix, a remote-tracking branch contains the commit, and the "not on any remote" list is empty.

The same three questions sort out the other causes of this symptom: a rejected push whose exit status a script ignored, a push to the wrong remote, a commit made on a detached HEAD, or a reader who looked at a stale remote-tracking ref instead of the server.

**Part 8: "my remote-tracking refs cannot be trusted".**

<!-- snippet: ch12/diagnose/05-ambiguous-name -->
```text
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git branch origin/main HEAD~1
$ git rev-parse --short origin/main
warning: refname 'origin/main' is ambiguous.
95671d3
$ git branch -a
  hotfix/timeout
* main
  origin/main
  remotes/origin/HEAD -> remotes/origin/main
  remotes/origin/hotfix/timeout
  remotes/origin/main
$ git branch -D origin/main
Deleted branch origin/main (was 95671d3).
```
<!-- /snippet -->

A local branch named `origin/main`, usually created by a mistyped command. Git warns that the name is ambiguous and then resolves it to the local branch, because `refs/heads/` comes before `refs/remotes/` in the lookup order. Every comparison "against `origin/main`" now uses the wrong commit. In `git branch -a` the impostor is the entry without the `remotes/` prefix.

**[ANIMATION]** graph: 95671d3-510ee94 main remote:origin/main; 95671d3 branch:origin/main#local; HEAD=main; note:95671d3:the_impostor,_a_local_branch title=Two_refs_called_origin/main dx=300

Here are the two names side by side: the remote-tracking ref on `510ee94`, and the impostor branch on `95671d3`.

<!-- snippet: ch12/diagnose/06-rebuild-remote-tracking -->
```text
$ git remote set-head origin --delete
$ git for-each-ref --format='delete %(refname)' refs/remotes/origin | git update-ref --stdin
$ git branch -r
$ git status -sb
## main...origin/main [gone]
$ git fetch
From ../../server/support-bot
 * [new branch]      main           -> origin/main
 * [new branch]      hotfix/timeout -> origin/hotfix/timeout
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

When the remote-tracking refs themselves are in doubt, remember what they are: a cache. Delete them all, 🟡, and fetch. Local branches and their upstream settings are not touched. Status says `[gone]` in between and is correct again afterwards. The price is the reflogs of the deleted refs, your only record of earlier server states.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Reading "Everything up-to-date" as "my commit is on the server".** Root cause: a push transfers the refs you name; the refspec `main` had nothing to send while the commit sat on another branch.
2. **Concluding that a branch does not exist because `git switch` says "invalid reference" in a CI workspace.** Root cause: the clone's fetch refspec names one branch, so no remote-tracking ref for the other was ever created.
3. **Removing the plus sign from a fetch refspec "for safety".** Root cause: without it a rewritten branch is rejected on fetch and the remote-tracking ref keeps recording a state the server no longer has.
4. **Adding a negative refspec and expecting existing refs to vanish.** Root cause: it excludes refs from later fetches and deletes nothing you already have.
5. **Creating a local branch called `origin/main`.** Root cause: `refs/heads/` is looked up before `refs/remotes/`, so the name resolves to the impostor, with only a warning.

## PRODUCTION EXAMPLE

**[ANIMATION]** flow: actors=the_connected_side,support-bot.bundle,*the_air-gapped_cluster msgs=1>2:git_bundle_create|1>2:git_bundle_verify|2>3:carry_the_file_across|3>2:git_clone_or_git_fetch|3>3:origin_is_the_bundle_file boundary=2 zones=has_a_route_to_the_server,no_route title=A_bundle_as_the_transport at_1=12 at_2=25 at_3=62 at_4=72 at_5=84

**[ANIMATION]** step: actors

Now, out of the lab. An ML platform team trains on an air-gapped cluster. There is no route from the cluster to the Git server. The training code still has to arrive as a Git repository, with history, so that a model artifact can record the commit it was built from.

**[ANIMATION]** step: 5

The transport for that is a bundle. Run `git bundle create` on the connected side, with `git bundle verify` printing the refs it contains and confirming that it records a complete history. Carry the file across. Clone or fetch from it on the other side. In the clone, `origin` is the bundle file.

**[ON SCREEN]** Layer label: GitHub.

For ordinary remotes, GitHub accepts HTTPS and SSH URLs. According to its blog, it stopped accepting account passwords for Git over HTTPS on 13 August 2021 and removed the unauthenticated `git://` protocol on 15 March 2022. Chapter 16 covers authentication.

**[ANIMATION]** step: rule.2

And the textbook's rule for refspec problems, which belongs on a team runbook: when a clone "cannot see" a branch or "keeps losing" one, print `git config get --all remote.origin.fetch` first.

## PRACTICE EXERCISE

Your turn. Do Lab 7.7, "Refspec surgery", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Predict before each fetch:

- Given the configured refspecs, which refs will this fetch create, move or leave alone?
- If the server's branch was rewritten, will the fetch accept or reject the update, and what decides it?
- For the last step of the lab: which of your refs is the destination of the refspec you are about to paste? Answer that before you run it.

The challenge is Incident 10, [`incidents/10-commit-local-not-remote`](../../incidents/10-commit-local-not-remote/SYMPTOMS.md). Read the symptoms file only.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q216: "In a CI workspace `git switch release/2.3` fails with an invalid reference although the branch exists on the server, and on a laptop a fetch rejects the update of a remote-tracking ref as a non-fast-forward. Diagnose both from what a refspec is."

**[PAUSE]**

Answer out loud first. A strong answer begins by defining a refspec in one sentence, with its three parts, and then uses that one definition twice. For each symptom it says which part of the refspec is responsible, which command prints the evidence, and which command changes the configuration. It also says how each clone came to have that refspec. Two symptoms, one concept: if your answer needs two unrelated explanations, start again.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: spec.2

A refspec maps source refs on the sending side to destination refs on the receiving side, and the plus sign allows a non-fast-forward update. A clone can only see the branches its fetch refspec covers, and `git remote set-branches` widens it. The URL selects the transport, and on the wire a fetch talks to `git-upload-pack` and a push to `git-receive-pack`. A bundle is a remote in a file.

**[ANIMATION]** step: where.state-2

"Everything up-to-date" is true of the refspec that was pushed, so I locate a commit with `git branch -a --contains`, check the upstream, and ask the server with `git ls-remote`.

**[ANIMATION]** end

Remote-tracking refs are a cache that can be deleted and fetched again.

## HOMEWORK

Read sections 12.12 to 12.17 of [Chapter 12](../../textbook/ch12-remote-operations.md), and do the Practice section 12.19.

That's the remotes module, complete. You can read a refspec, and you can find a commit that was "pushed" and isn't there, in under a minute. Do Lab 7.7 while this is fresh. Next time: the gate briefing for branching. Until then, look at the state first and type second. See you in the next one.

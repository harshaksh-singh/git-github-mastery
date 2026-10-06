# V041: git push: asking another repository to move its refs

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 7, Remote operations
- **Planned minutes:** 28
- **Prerequisites:** V040
- **Textbook sections:** [Chapter 12](../../textbook/ch12-remote-operations.md), sections 12.7 and 12.9
- **Demo scripts:** `labs/ch12/push-rejections.sh`, `labs/ch12/push-refs.sh`, `labs/ch12/push-errors.sh`, `labs/ch12/server-rules.sh`, `labs/ch12/push-non-bare.sh`

## HOOK

**[ON SCREEN]** Two lines, one above the other: `! [rejected] main -> main (fetch first)` and `! [rejected] main -> main (non-fast-forward)`.

Two engineers sit next to each other. Both have one local commit on `main`. Both push. One gets "fetch first". The other gets "non-fast-forward". They are in the same situation: a colleague pushed before them.

Why two messages for one cause? And here is the question that tells you whether someone understands push: in both cases, who said no? Their own Git, or the server? The answer is on the screen, in one word, and most people have never read it.

## INTRODUCTION

Fetch reads another repository. Push writes to one. That makes push the first command in this module that can change something you do not own, and so it is the first where another party gets a vote.

Today you follow one push through its seven steps and see where it can be refused, by whom, and with which words. Then you push the things that are not branches of the ordinary kind: deletions, tags, several refs at once. You look at pushes that fail before any comparison is made. You look at the rules a plain Git server can enforce. And you close with section 12.9: why Git refuses a push into a branch that somebody has checked out.

The server in the demos is a bare repository on disk. Where GitHub changes the picture, the label on screen says so.

## LEARNING OBJECTIVES

**[ON SCREEN]** The five objectives.

After this video you can:

- Describe a push as a request that the receiving repository may refuse.
- Tell `rejected (fetch first)` from `rejected (non-fast-forward)` and fix each.
- Push and delete branches and tags, and predict which refs travel.
- Explain "Everything up-to-date" when something you expected is not on the server.
- Explain why Git refuses a push into a checked-out branch.

## CONCEPT

In one sentence: `git push` 🟡 CAUTION asks a remote to make some of its refs point at commits of yours, sends the objects it lacks, and succeeds for each ref only if both your Git and the remote accept the update.

Read that sentence again for its three verbs. Asks. Sends. Succeeds only if both accept. A push is a request, and there are two gatekeepers.

A push runs in a fixed order, and you will have the order on screen as today's diagram. In short: your Git reads the server's refs. Your Git applies client rules to each ref you want to update. If they fail, nothing is sent. If they pass, your Git sends a line per ref, "old, new, ref name", plus a packfile. The server puts the objects into a quarantine directory, checks that the ref is still at the old value, applies its `receive.deny*` settings and runs its hooks. If all of that passes, the refs are updated. Last, your Git moves your remote-tracking ref.

The client rules are in the manual's "push rules": an existing branch may only be fast-forwarded, an existing tag may not be updated at all, and creations and deletions are allowed unless configuration or hooks forbid them.

With arguments, each refspec is, optional plus, source, colon, destination. The source is any commit expression of yours. The destination is a ref name on the remote.

Inside `.git`, in your repository, a push changes only the remote-tracking ref of each ref that was pushed, and its reflog. On the server: new objects and the updated refs.

**[ON SCREEN]** The state table for a successful push.

```text
Working tree   Index       HEAD        Current branch ref   Other refs and files in .git          Remote                         GitHub
------------   ---------   ---------   ------------------   -----------------------------------   ----------------------------   --------------------------
unchanged      unchanged   unchanged   unchanged            remote-tracking ref of each pushed    refs created, moved or         push events: pull request
                                                            ref and its reflog; upstream keys     deleted; new objects;          updates, workflow runs,
                                                            with -u                               hooks run                      rule evaluation
```

Your branch, your index and your working tree: unchanged. A push does not alter your work. It alters theirs.

And section 12.9 in two sentences. A push moves refs. It checks nothing out. So if the pushed ref is the branch that the receiving repository has checked out, that repository's HEAD would name a commit that its index and working tree do not match, and its next `git status` would present the pushed changes as local edits that undo them. Git refuses by default.

## MENTAL MODEL

**[ON SCREEN]** "`rejected` = my clerk. `remote rejected` = their office."

The textbook's analogy: posting entries to a shared ledger. "I have seen everything up to entry N; here are my entries after it." Your own clerk checks the claim before you reach the counter. Then the office applies its house rules.

Where it breaks: you can instruct your clerk to skip the check. That is force, and it is the next video. The office then refuses only if someone configured it to.

Carry the two gatekeepers with you. When the line says `! [rejected]`, your clerk stopped you; your clone must change. When it says `! [remote rejected]`, the office spoke; a policy on the server has to be read, and its owner asked.

## DIAGRAM

**[DIAGRAM]** Build the seven steps in order. Left column is your clone, right column is the server. Reveal each numbered line with its arrow, and colour the two exits: the client exit at step 2, the server exit at step 5.

```text
  your clone                                          server (git-receive-pack)

  1 read the server's refs                    <----   advertisement: refs/heads/main = 719650d
  2 client rules for each ref:
      fast-forward? tag exists? lease holds?
      no  -->  "! [rejected]"   (nothing is sent)
  3 send "<old> <new> <ref>" + packfile       ---->   4 objects go into a quarantine directory
                                                      5 ref still at <old>?  receive.deny* settings?
                                                        pre-receive and update hooks?
                                                        no  -->  "! [remote rejected]"
                                                      6 refs updated; post-receive hooks run
  7 move refs/remotes/origin/<branch>         <----   report: ok refs/heads/main
```

## LIVE TERMINAL DEMO

**[TERMINAL]** `labs/run ch12/push-rejections`. Asha has pushed. You have one local commit and a stale view.

**Part 1: one rule, two messages.**

```bash
git status -sb
git push
```

<!-- snippet: ch12/push-rejections/01-fetch-first -->
```text
$ git status -sb
## main...origin/main [ahead 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 1]
```
<!-- /snippet -->

`(fetch first)`. The server's `main` names a commit that your repository does not contain, so your Git cannot even test ancestry. The last status still shows the stale `[ahead 1]`, because a rejected push fetches nothing.

Now fetch, and push again. Predict the message.

**[PAUSE]**

<!-- snippet: ch12/push-rejections/02-non-fast-forward -->
```text
$ git fetch
From ../../server/support-bot
   510ee94..719650d  main       -> origin/main
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git push
To ../../server/support-bot.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
```
<!-- /snippet -->

`(non-fast-forward)`. After the fetch you have the server's commit, the ancestry test is possible, and it fails: the server's tip is not an ancestor of what you push, so accepting it would drop Asha's commit from `main`. One cause, two messages, and the only difference is whether you had fetched.

Now the word. Both lines say `! [rejected]`, not `! [remote rejected]`. Your own Git decided. Here is the proof, the client side of the conversation.

<!-- snippet: ch12/push-rejections/03-wire -->
```text
# The client side of the conversation during the rejected push:
$ GIT_TRACE_PACKET=1 git push 2>&1 | sed -n 's/.*packet: *\(push[<>]\)/\1/p' | fold -s -w 76
push< 719650da56c2910ce851d3c0f47ec270ebb88945 
refs/heads/main\0report-status report-status-v2 delete-refs side-band-64k 
quiet atomic ofs-delta object-format=sha1 agent=git/2.55.0-Darwin
push< 0000
push> 0000
```
<!-- /snippet -->

The server advertised its ref, the `push<` line with the ID that starts `719650d`. Your Git answered with an empty request, `push> 0000`, and closed the connection. The server was never asked.

The fix does not involve force.

<!-- snippet: ch12/push-rejections/04-integrate-and-push -->
```text
$ git rebase origin/main
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git push --dry-run
To ../../server/support-bot.git
   719650d..8bf53be  main -> main
$ git push
To ../../server/support-bot.git
   719650d..8bf53be  main -> main
$ git status -sb
## main...origin/main
$ git reflog show origin/main
8bf53be refs/remotes/origin/main@{0}: update by push
719650d refs/remotes/origin/main@{1}: fetch: fast-forward
```
<!-- /snippet -->

Integrate, a rebase here, a merge works as well. Preview with `--dry-run`. Push. And look at the reflog of `origin/main`: `update by push`. The successful push moved your remote-tracking ref immediately. Your Git knows what the server has now, so no fetch is needed.

**Part 2: pushes that fail before any comparison.** `labs/run ch12/push-errors`.

<!-- snippet: ch12/push-errors/01-src-refspec -->
```text
$ git branch
* hotfix/timeout
  main
$ git push origin master
error: src refspec master does not match any
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git push origin hotfix
error: src refspec hotfix does not match any
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/push-errors/02-unborn -->
```text
# A new repository with a remote but no commit yet:
$ git init -q ../../scratch
$ git -C ../../scratch remote add origin ../server/support-bot.git
$ git -C ../../scratch push -u origin main
error: src refspec main does not match any
error: failed to push some refs to '../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

`src refspec <name> does not match any` is about your side: the source name matched no ref of yours. Either the name is wrong, `master` where your branch is `main`, or half a branch name, or the repository has no commit yet, because an unborn branch is not a ref. The textbook notes that this message is among the thirty highest-voted Git questions on Stack Overflow.

<!-- snippet: ch12/push-errors/03-detached -->
```text
$ git switch --detach
HEAD is now at c19ab53 Set request timeout
$ git push
fatal: You are not currently on a branch.
To push the history leading to the current (detached HEAD)
state now, use

    git push origin HEAD:<name-of-remote-branch>

[exit status: 128]
$ git push origin HEAD:refs/heads/hotfix/timeout
To ../../server/support-bot.git
 * [new branch]      HEAD -> hotfix/timeout
$ git switch -
Switched to branch 'hotfix/timeout'
```
<!-- /snippet -->

With a detached HEAD there is no current branch whose upstream could supply a destination, so you name both sides. The destination is written in full, `refs/heads/...`, because a detached HEAD is not a ref under `refs/heads/` from which Git could infer that you mean a branch.

<!-- snippet: ch12/push-errors/04-no-such-remote -->
```text
$ git push orign hotfix/timeout
fatal: 'orign' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
$ git remote
origin
```
<!-- /snippet -->

A misspelled remote name is taken for a path to a repository, hence the misleading text about access rights.

**Part 3: deleting, tags, several refs.** `labs/run ch12/push-refs`.

`git push <remote> --delete <branch>` 🔴 DANGEROUS. The five answers. It changes one ref on the server. It can destroy the only name that the branch's commits have there, and a bare server keeps no record of the deletion. Preview with `git log --oneline origin/<branch> --not origin/main`, which lists the commits that only that branch holds. Recover by pushing the tip again from any clone that has it. It is appropriate for branches that are merged, or abandoned by agreement.

<!-- snippet: ch12/push-refs/01-delete-branch -->
```text
$ git push origin --delete feature/eval-harness
To ../../server/support-bot.git
 - [deleted]         feature/eval-harness
$ git branch -vv
  feature/eval-harness edc57ed [origin/feature/eval-harness: gone] Add eval harness entry point
* main                 510ee94 [origin/main] Add retrieval config
  release/0.1          510ee94 [origin/release/0.1] Add retrieval config
$ git ls-remote --branches origin
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/main
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/release/0.1
```
<!-- /snippet -->

The branch is gone on the server and so is your remote-tracking ref. Your local branch stays, with its upstream marked `gone`.

Tags. You create an annotated tag and a lightweight one and run a bare push. Predict the output.

**[PAUSE]**

<!-- snippet: ch12/push-refs/02-tags-are-not-pushed -->
```text
$ git tag -a v0.2.0 -m "Release 0.2.0"
$ git tag nightly
$ git push
Everything up-to-date
$ git ls-remote --tags origin
```
<!-- /snippet -->

"Everything up-to-date", and the server has no tags. That phrase means: for the refs this push selected, there was nothing to send. It does not mean that everything you made is on the server. Tags travel only when asked.

<!-- snippet: ch12/push-refs/03-push-tags -->
```text
$ git push origin v0.2.0
To ../../server/support-bot.git
 * [new tag]         v0.2.0 -> v0.2.0
$ git tag -a v0.2.1 -m "Release 0.2.1"
$ git push --follow-tags
To ../../server/support-bot.git
   510ee94..7aec635  main -> main
 * [new tag]         v0.2.1 -> v0.2.1
$ git ls-remote --tags origin
e4cbd524cd2ce2e1757843ad5ee0c371484fd6f9	refs/tags/v0.2.0
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/tags/v0.2.0^{}
3b6d020723c18782f5703818be9f01f07146e2f7	refs/tags/v0.2.1
7aec635a45c70d81f8a60b04ce73a0dcfdbb15c8	refs/tags/v0.2.1^{}
```
<!-- /snippet -->

`git push origin <tag>` pushes one. `--follow-tags` adds annotated tags that point into the commits being pushed: `v0.2.1` went, the lightweight `nightly` did not. `--tags` pushes all of them.

<!-- snippet: ch12/push-refs/04-tag-update-rejected -->
```text
$ git tag -f -a v0.2.0 -m "Release 0.2.0, retagged"
Updated tag 'v0.2.0' (was e4cbd52)
$ git push origin v0.2.0
To ../../server/support-bot.git
 ! [rejected]        v0.2.0 -> v0.2.0 (already exists)
error: failed to push some refs to '../../server/support-bot.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
```
<!-- /snippet -->

That is the tag rule: a tag that exists on the remote is not replaced without force.

Now two refs in one push. `main` is behind the server; `release/0.1` is one commit ahead. First with `--atomic`. Predict what happens to `release/0.1`.

**[PAUSE]**

<!-- snippet: ch12/push-refs/05-atomic -->
```text
# main is behind the server (Asha pushed); release/0.1 is one commit ahead.
$ git config set advice.pushUpdateRejected false
$ git push --atomic origin main release/0.1
error: atomic push failed for ref refs/heads/main. status: 5
To ../../server/support-bot.git
 ! [rejected]        main -> main (fetch first)
 ! [rejected]        release/0.1 -> release/0.1 (atomic push failed)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
bb34561abaa5aa4fabf570a6dd8417f74b6abb81	refs/heads/main
510ee948fb6354959cf03862f0ebe47c58eb2a74	refs/heads/release/0.1
```
<!-- /snippet -->

Nothing was sent, because one ref failed. Without `--atomic`:

<!-- snippet: ch12/push-refs/06-not-atomic -->
```text
$ git push origin main release/0.1
To ../../server/support-bot.git
   510ee94..0c10e7b  release/0.1 -> release/0.1
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
$ git ls-remote --branches origin
bb34561abaa5aa4fabf570a6dd8417f74b6abb81	refs/heads/main
0c10e7b5f43e3b449f31c690a82fee2a5af38d81	refs/heads/release/0.1
```
<!-- /snippet -->

`release/0.1` was updated although `main` was rejected, and the exit status is 1. Refs in one push are independent by default. A release script that pushes a branch and a tag needs `--atomic` and must check the exit status.

**Part 4: the server's own rules.** `labs/run ch12/server-rules`. The demo uses `--force` here only to get past your own clerk and let the office speak; force itself is the next video.

<!-- snippet: ch12/server-rules/01-deny-non-fast-forwards -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git -C ../../server/support-bot.git config set receive.denyNonFastForwards true
$ git push --force
remote: error: denying non-fast-forward refs/heads/main (you should pull first)        
To ../../server/support-bot.git
 ! [remote rejected] main -> main (non-fast-forward)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

Read the line: `! [remote rejected]`. And above it a `remote:` line carrying the server's own words. `--force` switches off your Git's checks, not the server's.

<!-- snippet: ch12/server-rules/02-deny-deletes -->
```text
$ git push origin HEAD:refs/heads/tmp/scratch
To ../../server/support-bot.git
 * [new branch]      HEAD -> tmp/scratch
$ git -C ../../server/support-bot.git config set receive.denyDeletes true
$ git push origin --delete tmp/scratch
remote: error: denying ref deletion for refs/heads/tmp/scratch        
To ../../server/support-bot.git
 ! [remote rejected] tmp/scratch (deletion prohibited)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

<!-- snippet: ch12/server-rules/03-pre-receive -->
```text
$ git -C ../../server/support-bot.git config unset receive.denyNonFastForwards
$ cp ../../pre-receive ../../server/support-bot.git/hooks/pre-receive
$ chmod +x ../../server/support-bot.git/hooks/pre-receive
$ cat ../../server/support-bot.git/hooks/pre-receive
#!/bin/sh
# Refuse every direct update of main. Standard input has one line per ref:
#   <old-id> <new-id> <ref-name>
while read old new ref; do
  if [ "$ref" = "refs/heads/main" ]; then
    echo "policy: main only changes through a reviewed merge" >&2
    exit 1
  fi
done
exit 0
$ git push --force
remote: policy: main only changes through a reviewed merge        
To ../../server/support-bot.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/support-bot.git'
[exit status: 1]
```
<!-- /snippet -->

A `pre-receive` hook reads one "old new ref" line per proposed update and can refuse the whole push, while the pushed objects wait in quarantine. Here it refuses every direct update of `main`, and its message reaches you on a `remote:` line.

**Part 5: a repository with a working tree.** `labs/run ch12/push-non-bare`. `staging-box` is an ordinary clone with `main` checked out. Predict.

**[PAUSE]**

<!-- snippet: ch12/push-non-bare/01-refused -->
```text
$ git remote add staging ../../staging-box
$ git push staging main
remote: error: refusing to update checked out branch: refs/heads/main        
remote: error: By default, updating the current branch in a non-bare repository        
remote: is denied, because it will make the index and work tree inconsistent        
remote: with what you pushed, and will require 'git reset --hard' to match        
remote: the work tree to HEAD.        
remote: 
remote: You can set the 'receive.denyCurrentBranch' configuration variable        
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into        
remote: its current branch; however, this is not recommended unless you        
remote: arranged to update its work tree to match what you pushed in some        
remote: other way.        
remote: 
remote: To squelch this message and still keep the default behaviour, set        
remote: 'receive.denyCurrentBranch' configuration variable to 'refuse'.        
To ../../staging-box
 ! [remote rejected] main -> main (branch is currently checked out)
error: failed to push some refs to '../../staging-box'
[exit status: 1]
```
<!-- /snippet -->

"Refusing to update checked out branch." `receive.denyCurrentBranch` defaults to `refuse`. Any branch that is not checked out can be pushed to.

<!-- snippet: ch12/push-non-bare/02-other-branch -->
```text
$ git push staging main:refs/heads/incoming/timeout
To ../../staging-box
 * [new branch]      main -> incoming/timeout
$ git -C ../../staging-box branch -vv
  incoming/timeout c19ab53 Set request timeout
* main             510ee94 [origin/main] Add retrieval config
```
<!-- /snippet -->

For the legitimate case, a test or deployment machine that you reach over SSH, the receiving side can opt in to `updateInstead`, which updates the working tree as part of the push.

<!-- snippet: ch12/push-non-bare/03-update-instead -->
```text
$ git -C ../../staging-box config set receive.denyCurrentBranch updateInstead
$ git push staging main
To ../../staging-box
   510ee94..c19ab53  main -> main
$ git -C ../../staging-box log --oneline -1
c19ab53 Set request timeout
$ ls ../../staging-box/app
retriever.py
settings.py
```
<!-- /snippet -->

<!-- snippet: ch12/push-non-bare/04-dirty-target -->
```text
$ printf 'hotfix typed directly on the box\n' >> ../../staging-box/README.md
$ git push staging main
To ../../staging-box
 ! [remote rejected] main -> main (Working directory has unstaged changes)
error: failed to push some refs to '../../staging-box'
[exit status: 1]
```
<!-- /snippet -->

It works only while the target is clean. One uncommitted edit on the box makes every later push fail with "Working directory has unstaged changes", which is the correct outcome: somebody hot-fixed on the machine, and the push tells you before it overwrites anything. The general rule stands: a repository that people push to is bare.

## COMMON MISTAKES

**[ON SCREEN]** Each mistake with its root cause.

1. **Answering a rejection with `--force`.** Root cause: `rejected` means the server's tip is not an ancestor of yours, so forcing would drop the other person's commit; the fix is to fetch and integrate.
2. **Not reading whether the line says `rejected` or `remote rejected`.** Root cause: they come from different gatekeepers, your own Git at step 2 or the server at step 5, and need different responses.
3. **Assuming a release tag was pushed because the branch was.** Root cause: tags are not pushed unless named, or selected by `--follow-tags` or `--tags`.
4. **Pushing a branch and a tag in one command and trusting partial success.** Root cause: refs in one push are independent unless `--atomic` is given, and the exit status is 1 either way.
5. **Typing `git push origin master` in a repository whose branch is `main`.** Root cause: `src refspec does not match any` means the source name matched no ref on your side.

## PRODUCTION EXAMPLE

**[ON SCREEN]** "'It said rejected' is not a diagnosis."

An on-call engineer for a model-serving team tries to push a hotfix and reports: "it said rejected". The textbook's reply is the title of this slide. Read the word before the bracket closes.

`rejected` means your clone must change: fetch and integrate. `remote rejected` means a policy on the server spoke: read the `remote:` lines and talk to whoever owns that policy. Retrying with `--force` answers neither.

**[ON SCREEN]** Layer label: GitHub.

On GitHub the server-side rules are rulesets, branch protection and push protection. They answer in the same shape. GitHub's documentation gives `remote: error: GH006: Protected branch update failed for refs/heads/main.` as the reply of a branch protection rule. Chapter 18 covers them. This is described from the documentation and was not captured here.

So the skill transfers. On a plain Git server the office's rules are `receive.denyNonFastForwards`, `receive.denyDeletes` and hooks. On GitHub they have other names and more features. In both, the reply arrives on `remote:` lines and the status line says `remote rejected`.

## PRACTICE EXERCISE

Do Lab 7.2, "A rejected push, then fetch and integrate by merge and by rebase", in [`lab-manual/m07-remotes.md`](../../lab-manual/m07-remotes.md).

Predict before each command:

- Which of the two rejection messages will the first push print, and why that one?
- After the fetch, what will the second push print, and what does `git status -sb` show?
- After integrating by merge and then again by rebase: what does the graph look like, and what is the top entry of `git reflog show origin/main` after the successful push?

The challenge is Exercise 7.10, Level 5, "the hotfix that was pushed and is not on the server", in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q206: "Two engineers in the same situation got `rejected (fetch first)` and `rejected (non-fast-forward)`. Explain the difference and who made each decision. How is `remote rejected` different?"

Answer aloud first. A strong answer places all three messages on the steps of a push and says, for each, which side had the information and which side decided. It explains the two client messages as two states of knowledge about the same graph, and it can say what evidence shows that the server was never asked. For `remote rejected` it names at least two things on a server that can produce it and says where the server's explanation appears. It ends with what the engineer should do in each case, and force is in none of them.

## RECAP

You should now be able to say:

A push is a request: my Git checks the client rules first, and the receiving repository applies its own rules after that. `rejected (fetch first)` and `rejected (non-fast-forward)` are the same refusal by my own Git, before and after I have fetched; the fix is to integrate and push again. `remote rejected` is the server's policy speaking on `remote:` lines. Tags are pushed only when named, refs in one push are independent unless I pass `--atomic`, and "Everything up-to-date" speaks only about the refs that push selected. A push moves refs and checks nothing out, so Git refuses to update a checked-out branch in a non-bare repository.

## HOMEWORK

Read sections 12.7 and 12.9 of [Chapter 12](../../textbook/ch12-remote-operations.md).

Do Exercise 7.3, Level 1, "publish a branch, then delete it on the server", and Exercise 7.8, Level 3, "a push that the other side refuses", both in [`exercises/m06-m10-integration.md`](../../exercises/m06-m10-integration.md).

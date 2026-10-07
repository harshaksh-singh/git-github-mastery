# V081: Why a published tag must not move

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 13, Tags and versions
- **Planned minutes.** 18
- **Prerequisites.** V039, V080
- **Textbook sections.** [Chapter 14B](../../textbook/ch14b-config-tags-signing.md), section 14B.11
- **Demo scripts.** `labs/ch14b/moved-tag.sh`

## HOOK

**[ON SCREEN]** "The container labelled `v1.2.0` in production does not contain the fix that the tag `v1.2.0` contains on my laptop. Which one is `v1.2.0`?"

Here's how that happens. Version 1.2.0 is released on a Monday morning. An hour later someone finds a bug in a limit. The fix is one line. It lands on `main`. And then a well-meaning engineer thinks: the release is only an hour old, hardly anyone has it, let me correct the tag so that 1.2.0 includes the fix. Almost everyone has thought it.

Git refuses twice. The engineer adds a force flag twice. From that moment two different pieces of code are called 1.2.0, and no command that any of your colleagues runs in the normal course of a day will tell them. So which one is 1.2.0? Keep the question.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the previous video you learned three facts. A tag is a ref, a name that holds an object ID, and every clone holds it separately. A push sends it only when asked. And a fetch never updates a tag you already have. Each fact was harmless on its own. Today you put them together and reproduce the incident between three clones: the releaser, a colleague who fetched before the move, and a CI machine, an automated build server, that cloned after it.

Then you detect the disagreement, repair it with the lowest-risk action, and look at prevention on the server, including two settings whose names suggest that they help, and don't.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- reproduce a moved tag between two clones and say who has which version;
- explain why `git fetch` keeps the old tag and what `--force` changes;
- detect the disagreement by comparing local tags with the server;
- repair it with the lowest-risk action and say why a new version number is that action;
- name the server-side settings that refuse a tag update on a plain Git server.

## CONCEPT

**[ANIMATION]** remotes: id=moved title=One_name,_two_commits [the server] ...older-d20ef7a main; d20ef7a atag:v1.2.0#5b231b5; HEAD=none || [Asha's clone] ...older-d20ef7a main origin/main; d20ef7a atag:v1.2.0#5b231b5; HEAD=main => [the server] ...older-d20ef7a-2518733 main; 2518733 atag:v1.2.0#5a0dc77; HEAD=none; cmd:!git_push_--force_origin_v1.2.0; say:The_fix_lands_on_main,_and_v1.2.0_is_moved_onto_it; name:forced || => || [Asha's clone] ...older-d20ef7a-2518733 main origin/main; d20ef7a atag:v1.2.0#5b231b5; HEAD=main; cmd:git_pull; say:Her_pull_moves_main,_and_her_tag_stays; name:kept => [the server] ...older-d20ef7a-2518733 main; d20ef7a atag:v1.2.0#5b231b5; 2518733 atag:v1.2.1; HEAD=none; cmd:git_tag_-a_v1.2.1; say:Put_v1.2.0_back_where_it_was_published,_release_the_fix_as_v1.2.1; name:repair ||

**[ANIMATION]** step: forced

In one sentence: every clone keeps its own copy of each tag and never updates it by itself. So moving a tag on the server doesn't move it anywhere else. It creates two things with one name. On screen, the server and Asha's clone from today's demo: the fix lands on `main`, and then `v1.2.0` is moved onto it.

**[ANIMATION]** step: kept

Why does Git behave this way? Because a tag name is a promise about content. The manual says that Git "does not (and it should not) change tags behind users back". A fetch creates missing tags and refuses to overwrite existing ones. So in Asha's clone a pull moves `main`, and her tag stays. A plain fetch doesn't even report the difference.

**[ANIMATION]** end

What moving a tag takes. Locally, `git tag -f`. That is 🟡 CAUTION: it rewrites the ref, the old tag object becomes unreachable, and there is no reflog. Git prints the old ID once, "Updated tag (was ...)", and that line is the only record. On the server, `git push --force origin <tag>`, which is 🔴 DANGEROUS.

**[ANIMATION]** say: Compare_IDs:_the_server's_v1.2.0_peels_to_2518733,_Asha's_to_d20ef7a

How to detect it. Ask the server for the peeled tag with `git ls-remote` and compare with your own `git rev-parse` of the tag peeled to a commit. Peeled means followed through the tag object to its commit. `git fetch --tags` also reports the clash, as "would clobber existing tag".

**[ANIMATION]** step: repair

How to repair it. The textbook's fix has two halves. Put the tag back where it was published. And release the new content under a new name.

**[ANIMATION]** say: A_new_version_number_changes_nothing_that_anyone_already_has

Why is a new version number the low-risk action? Because it changes nothing that anyone already has. Every clone, every cache and every built artifact that says 1.2.0 becomes right again, and the fix is available as 1.2.1 to anyone who asks for it. Any other repair requires reaching every machine that ever fetched the tag.

**[ANIMATION]** end

Clones that picked up the moved tag in between must be corrected by hand, with `git fetch --tags --force`. That is 🟡 CAUTION: it overwrites local tags with the server's.

How to prevent it. On the server. On a plain Git server, with a hook, a program Git runs at a fixed point. On GitHub, with a tag ruleset. And in your deployment process: deploy by commit ID or image digest, not by tag name alone.

When is a forced tag push appropriate at all? The safety table gives one case: putting a tag back at its published position. A name that is meant to move should be a branch.

## MENTAL MODEL

**[ANIMATION]** remotes: id=three dx=150 title=Three_repositories,_one_tag_name [the server] ...older-d20ef7a main; d20ef7a atag:v1.2.0#5b231b5; HEAD=none || [Asha's clone] ...older-d20ef7a main origin/main; d20ef7a atag:v1.2.0#5b231b5; HEAD=main || [CI clone] HEAD=none => [the server] ...older-d20ef7a-2518733 main; 2518733 atag:v1.2.0#5a0dc77; HEAD=none; say:A_new_certificate_with_the_same_title,_filed_in_one_office; name:forced || || => || [Asha's clone] ...older-d20ef7a-2518733 main origin/main; d20ef7a atag:v1.2.0#5b231b5; HEAD=main; say:An_office_that_already_holds_one_keeps_it; name:kept || => || || [CI clone] ...older-d20ef7a-2518733 main origin/main; 2518733 atag:v1.2.0#5a0dc77; HEAD=main; say:An_office_that_opens_after_the_change_gets_the_new_one; name:opened => [the server] ...older-d20ef7a-2518733 main; d20ef7a atag:v1.2.0#5b231b5; 2518733 atag:v1.2.1; HEAD=none; say:v1.2.0_is_back_on_d20ef7a,_and_the_fix_is_v1.2.1; name:repair || || => || || [CI clone] ...older-d20ef7a-2518733 main origin/main; 2518733 atag:v1.2.0#5a0dc77 atag:v1.2.1; HEAD=main; cmd:git_fetch; say:A_plain_fetch_brings_v1.2.1_and_keeps_the_wrong_v1.2.0; name:plain => || || [CI clone] ...older-d20ef7a-2518733 main origin/main; d20ef7a atag:v1.2.0#5b231b5; 2518733 atag:v1.2.1; HEAD=main; cmd:git_fetch_--tags_--force; say:Only_a_forced_tag_fetch_corrects_this_clone; name:corrected at_corrected=40

**[ANIMATION]** step: forced

Use the certificates from the last video: an annotated tag is a certificate that cites a page of the ledger. Every clone has its own copy of the certificate "v1.2.0 cites page d20ef7a". Moving the tag on the server writes a new certificate with the same title that cites a different page, and files it at the front desk of one office.

**[ANIMATION]** step: opened

Offices that already hold a certificate with that title keep theirs. That's a policy, not an oversight: a clerk who silently replaced certificates would make every certificate worthless. Offices that open after the change get the new one. Nobody is told that two exist.

**[ANIMATION]** say: Compare_IDs:_5b231b5_peels_to_d20ef7a,_5a0dc77_peels_to_2518733

Where the model breaks: paper certificates could be compared by a date stamp. Two tag objects with the same name are distinguished only by their object IDs and by the commit each one peels to. So the comparison you run is always between IDs.

## DIAGRAM

Try it now, on paper. Pause me for thirty seconds and draw three boxes: the server, Asha's clone, and a CI clone made after the move. Your answer for each: which commit is `v1.2.0`?

**[PAUSE]**

**[DIAGRAM]** The picture of section 14B.11: three boxes, each with the commit its tag names. Draw the server box before the move, then the move, then the two clones.

```text
  server                      Asha's clone                 CI clone (cloned after the move)
  v1.2.0 -> 2518733 (moved)   v1.2.0 -> d20ef7a (kept)     v1.2.0 -> 2518733
  d20ef7a  Add rate limits       <- what was released as 1.2.0
  2518733  Fix max_tokens limit  <- what the server now calls 1.2.0
```

Three repositories, one tag name, two commits. Asha's clone has the commit that was released. The CI clone has the commit that the server now calls 1.2.0. Both will build something labelled 1.2.0.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14b/moved-tag`. The release as it was published.

```bash
git log --oneline --decorate
git ls-remote --tags origin
```

<!-- snippet: ch14b/moved-tag/01-released -->
```text
$ git log --oneline --decorate
d20ef7a (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git ls-remote --tags origin
5b231b5f068120dabb9fbf2ab18bb2c3ea07ded5	refs/tags/v1.2.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.2.0^{}
```
<!-- /snippet -->

`v1.2.0` is the tag object `5b231b5`, and it peels to commit `d20ef7a`. You and Asha both have it. Now the fix lands and the tag is "corrected".

**[ON SCREEN]** 🔴 DANGEROUS: `git push --force origin <tag>`. The five answers, before the command runs. What it changes: it replaces a published tag on the server. What it can destroy: the meaning of a release name for everyone who fetches later. How to preview: `git ls-remote --tags origin`. How to recover: force the old tag object back from a clone that has it. When it is appropriate: for putting a tag back at its published position. That is not what is about to happen; watch it done wrongly.

```bash
git commit -q -am "Fix max_tokens limit"
git push -q
git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"
git push origin v1.2.0
git push --force origin v1.2.0
```

<!-- snippet: ch14b/moved-tag/02-move -->
```text
# A bug is found an hour after the release. The fix lands on main, and the tag is "corrected".
$ printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml
$ git commit -q -am "Fix max_tokens limit"
$ git push -q
$ git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"
Updated tag 'v1.2.0' (was 5b231b5)
$ git push origin v1.2.0
To ../../server/inference-gateway.git
 ! [rejected]        v1.2.0 -> v1.2.0 (already exists)
error: failed to push some refs to '../../server/inference-gateway.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
$ git push --force origin v1.2.0
To ../../server/inference-gateway.git
 + 5b231b5...5a0dc77 v1.2.0 -> v1.2.0 (forced update)
```
<!-- /snippet -->

Count the refusals. `git tag` needed `-f` and printed "(was 5b231b5)". The push was rejected: "already exists". Only `--force` got through. Two safety nets, both overridden.

Now Asha pulls.

**[PAUSE]** Predict: after this pull, what does Asha's clone report for `v1.2.0`? Her `main` will have the fix.

```bash
git pull
git log --oneline --decorate
```

<!-- snippet: ch14b/moved-tag/03-asha -->
```text
$ cd ../../asha/inference-gateway
$ git pull
From ../../server/inference-gateway
   d20ef7a..2518733  main       -> origin/main
Updating d20ef7a..2518733
Fast-forward
 config/limits.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --decorate
2518733 (HEAD -> main, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 2048
```
<!-- /snippet -->

Her `main` is at `2518733`, with the fix. Her `v1.2.0` is where it always was, on `d20ef7a`. The pull printed nothing about the tag. A machine that clones now gets the other one.

```bash
git clone -q server/inference-gateway.git ci/inference-gateway
git log --oneline --decorate
git show v1.2.0:config/limits.yaml
```

<!-- snippet: ch14b/moved-tag/04-fresh-clone -->
```text
$ cd ../..
$ git clone -q server/inference-gateway.git ci/inference-gateway
$ cd ci/inference-gateway
$ git log --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 4096
```
<!-- /snippet -->

**[ANIMATION]** step: three.opened

**[ANIMATION]** say: Same_tag_name,_two_commits:_d20ef7a_has_2048,_2518733_has_4096

In the CI clone, `v1.2.0` decorates `2518733`, and the limits file at that tag says `max_tokens: 4096`. In Asha's clone the same tag has 2048. Both builds are labelled 1.2.0.

Detect it, from Asha's clone.

```bash
git ls-remote origin 'refs/tags/v1.2.0^{}'
git rev-parse 'v1.2.0^{commit}'
git fetch --tags
```

<!-- snippet: ch14b/moved-tag/05-detect -->
```text
$ cd ../../asha/inference-gateway
# What the server says the tag is, and what this clone says it is:
$ git ls-remote origin 'refs/tags/v1.2.0^{}'
2518733b711886bd82418641eb2434765079e288	refs/tags/v1.2.0^{}
$ git rev-parse 'v1.2.0^{commit}'
d20ef7a61e04035281b8b38ed0d78ee612252220
$ git fetch --tags
From ../../server/inference-gateway
 ! [rejected] v1.2.0     -> v1.2.0  (would clobber existing tag)
[exit status: 1]
```
<!-- /snippet -->

The server says `2518733`. This clone says `d20ef7a`. And `git fetch --tags` rejects the update: "would clobber existing tag".

**[ON SCREEN]** The root-cause box of section 14B.11.

```text
Observed behavior : two builds labelled v1.2.0 contain different code.
Git state         : refs/tags/v1.2.0 names d20ef7a in clones that fetched before the move and
                    2518733 on the server and in clones made after it.
Mechanism         : fetch creates missing tags and refuses to overwrite existing ones ("would
                    clobber existing tag"); a plain fetch does not even report the difference.
Root cause        : a published tag was replaced with git tag -f and git push --force.
Why Git does this : a tag name is a promise about content. The manual: Git "does not (and it
                    should not) change tags behind users back".
Correct fix       : put the tag back where it was published; release the new content under a new name.
Prevention        : server-side rule that existing release tags cannot be updated or deleted;
                    deploy by commit ID or image digest, not by tag name alone.
```

Repair it. Asha's clone still has the original tag object, so she can restore it. This is the one appropriate use of the forced tag push.

```bash
git push --force origin v1.2.0
git fetch --tags --force
git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
git push origin v1.2.1
```

<!-- snippet: ch14b/moved-tag/06-repair -->
```text
# The sane repair: put v1.2.0 back where it was published, and release the fix as v1.2.1.
# Asha still has the original tag object, so she can restore it.
$ git push --force origin v1.2.0
To ../../server/inference-gateway.git
 + 5a0dc77...5b231b5 v1.2.0 -> v1.2.0 (forced update)
$ cd ../../you/inference-gateway
$ git fetch --tags --force
From ../../server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
$ git push origin v1.2.1
To ../../server/inference-gateway.git
 * [new tag]         v1.2.1 -> v1.2.1
$ git log --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.1, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
73c05d1 Add model router
dfbc830 Add README
```
<!-- /snippet -->

The first command runs in Asha's clone and puts `5b231b5` back on the server. The rest run in yours: you take the server's tag by force, and release the fix as `v1.2.1`. If nobody had kept the original ref, the tag object is usually still in someone's object database as a "dangling tag". The lab does that search.

**[ANIMATION]** step: three.repair

Is everyone right now? Predict what the CI clone shows after an ordinary fetch. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git fetch
git log -2 --oneline --decorate
git fetch --tags --force
git log -2 --oneline --decorate
```

<!-- snippet: ch14b/moved-tag/07-ci-still-wrong -->
```text
$ cd ../../ci/inference-gateway
$ git fetch
From $LAB/ch14b/moved-tag/server/inference-gateway
 * [new tag]         v1.2.1     -> v1.2.1
$ git log -2 --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.1, tag: v1.2.0, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a Add rate limits
$ git fetch --tags --force
From $LAB/ch14b/moved-tag/server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ git log -2 --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.1, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
```
<!-- /snippet -->

After the plain fetch, the CI clone has `v1.2.1` and `v1.2.0` on the same commit. It received the new tag and kept its wrong copy of the old one.

**[ANIMATION]** step: three.corrected

Only `git fetch --tags --force` corrects it. Every clone and cache that fetched in the bad interval needs this by hand.

**[ANIMATION]** end

Prevention. Two settings of plain Git sound as if they would help.

```bash
git -C ../../server/inference-gateway.git config set receive.denyNonFastForwards true
git -C ../../server/inference-gateway.git config set receive.denyDeletes true
git tag -a v1.3.0-rc.1 -m "Release candidate"
git push -q origin v1.3.0-rc.1
git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved" HEAD~1
git push --force origin v1.3.0-rc.1
```

Quick quiz, two options. With both settings on, the forced tag push is refused. Or it's accepted. Say it out loud.

**[PAUSE]**

<!-- snippet: ch14b/moved-tag/08-server-settings -->
```text
# Two server settings that sound as if they protect tags. Set them and try.
$ cd ../../you/inference-gateway
$ git -C ../../server/inference-gateway.git config set receive.denyNonFastForwards true
$ git -C ../../server/inference-gateway.git config set receive.denyDeletes true
$ git tag -a v1.3.0-rc.1 -m "Release candidate"
$ git push -q origin v1.3.0-rc.1
$ git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved" HEAD~1
Updated tag 'v1.3.0-rc.1' (was d15e77e)
$ git push --force origin v1.3.0-rc.1
To ../../server/inference-gateway.git
 + d15e77e...cc3836f v1.3.0-rc.1 -> v1.3.0-rc.1 (forced update)
[exit status: 0]
$ git push origin --delete v1.3.0-rc.1
To ../../server/inference-gateway.git
 - [deleted]         v1.3.0-rc.1
[exit status: 0]
```
<!-- /snippet -->

Accepted, exit status 0. If you said refused, the names do suggest it. The textbook cites the source: in Git 2.55.0 the code behind these two settings applies them only to refs under `refs/heads/`, and the manual's wording doesn't say so. On a plain Git server, tags are protected by a hook.

```bash
cat ../../update-hook
```

<!-- snippet: ch14b/moved-tag/09-update-hook -->
```text
# A server-side update hook: an existing tag under refs/tags/v* can be neither moved nor deleted.
$ cat ../../update-hook
#!/bin/sh
# update hook: called once per ref with <ref> <old-id> <new-id>.
# A release tag may be created. It may not be moved or deleted.
ref=$1 old=$2
case "$ref" in
refs/tags/v*)
  if ! printf '%s' "$old" | grep -q '^0*$'; then
    echo "policy: $ref is published and immutable; release a new version" >&2
    exit 1
  fi ;;
esac
exit 0
$ cp ../../update-hook ../../server/inference-gateway.git/hooks/update
$ chmod +x ../../server/inference-gateway.git/hooks/update
$ git push -q origin v1.3.0-rc.1
$ git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved again" HEAD
Updated tag 'v1.3.0-rc.1' (was cc3836f)
$ git push --force origin v1.3.0-rc.1
remote: policy: refs/tags/v1.3.0-rc.1 is published and immutable; release a new version        
remote: error: hook declined to update refs/tags/v1.3.0-rc.1        
To ../../server/inference-gateway.git
 ! [remote rejected] v1.3.0-rc.1 -> v1.3.0-rc.1 (hook declined)
error: failed to push some refs to '../../server/inference-gateway.git'
[exit status: 1]
$ git push origin --delete v1.3.0-rc.1
remote: policy: refs/tags/v1.3.0-rc.1 is published and immutable; release a new version        
remote: error: hook declined to update refs/tags/v1.3.0-rc.1        
To ../../server/inference-gateway.git
 ! [remote rejected] v1.3.0-rc.1 (hook declined)
error: failed to push some refs to '../../server/inference-gateway.git'
[exit status: 1]
```
<!-- /snippet -->

An update hook is called once per ref with the ref name, the old ID and the new ID. For a ref under `refs/tags/v`, if the old ID isn't all zeros, the tag exists already, and the hook refuses. A release tag may be created. It may not be moved or deleted.

**[ON SCREEN]** Lower third: **GitHub**. On GitHub the equivalent is a tag ruleset that restricts updates and deletions. The textbook notes that tag protection rules were retired in August 2024 in favor of rulesets. A release is a GitHub object layered on a Git tag, and an immutable release additionally locks the tag and its assets. Rulesets and releases have their own videos in the GitHub part.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"Correcting" a release tag an hour after publishing it.** Root cause: every clone that fetched keeps its copy, so the move creates two things with one name instead of changing one.
2. **Believing that a pull or fetch brings the corrected tag.** Root cause: fetch creates missing tags and refuses to overwrite existing ones; a plain fetch does not even report the difference.
3. **Relying on `receive.denyNonFastForwards` to protect tags.** Root cause: in Git 2.55.0 the code applies it, and `receive.denyDeletes`, only to refs under `refs/heads/`.
4. **Repairing by moving the tag a third time.** Root cause: each move adds another interval in which clones captured a different value; the only stable value is the one originally published.
5. **Deploying by tag name alone.** Root cause: a tag is a mutable name held by someone else; the commit ID or image digest is the content.

## PRODUCTION EXAMPLE

Now, out of the lab. The CTO's question is also a supply-chain question. The research report behind this course records that third-party GitHub Actions referenced by tag were repointed in real attacks, which is why the course pins actions by full commit ID. The mechanism is exactly today's: a tag is a mutable name held by someone else.

A model-serving team applies the lesson to its own releases. The build writes the full commit ID and the image digest into the deployment record next to the tag name. The production deploy job refuses to proceed if the tag on the server doesn't peel to the recorded commit. And the repository has a rule that existing release tags can't be updated or deleted. When a bug is found an hour after a release, the conversation is short: the fix is the next patch version. So which one is 1.2.0? The one published first.

## PRACTICE EXERCISE

Your turn. Do Lab 13.2, "A moved tag between two clones", in [`lab-manual/m13-tags-versions.md`](../../lab-manual/m13-tags-versions.md).

Before each fetch or pull in the lab, write down for each clone which commit its `v1.2.0` names afterwards. Before the repair, predict which clones will still be wrong after an ordinary fetch, and which command corrects each of them.

The challenge is Exercise 13.9, Level 4, "Two builds of 1.4.0", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q113: "A release tag was force-moved yesterday. Who has which version of it today, how do you find out, and what is the lowest-risk repair?"

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** replay: three

A strong answer sorts the population by when each clone, cache or build first obtained the tag, and says which commit each group holds and why. It gives a detection that compares IDs between a clone and the server and can be run on any machine. For the repair it gives both halves and argues why a new version number is lower risk than any further move of the old name. It says what remains to be done by hand afterwards and for whom. And it ends with prevention at two levels: the server, and the way deployments identify what they deploy.

## RECAP

Let's land this. You should now be able to say:

- A tag exists once per clone; moving it on the server changes one copy.
- Fetch creates missing tags and refuses to overwrite existing ones, so old clones and new clones disagree silently.
- I detect a moved tag by comparing the server's peeled tag with mine.
- The repair is to restore the published tag and ship the change as a new version; stragglers need `git fetch --tags --force`.
- Tag immutability is enforced on the server: by a hook on plain Git, by a ruleset on GitHub.

## HOMEWORK

Read section 14B.11 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md). Do Exercise 13.7, Level 3, "The version that will not move", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you reproduced a real release incident, detected it by comparing IDs, and repaired it with a new version number. Run the moved-tag lab before the next video. Next time: `git describe`, Semantic Versioning, and release branches. Until then, look at the state first and type second. See you in the next one.

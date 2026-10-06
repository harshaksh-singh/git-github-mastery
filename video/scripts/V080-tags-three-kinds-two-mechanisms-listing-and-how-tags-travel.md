# V080: Tags: three kinds, two mechanisms, listing, and how tags travel

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 13, Tags and versions
- **Planned minutes.** 22
- **Prerequisites.** V008, V026
- **Textbook sections.** [Chapter 14B](../../textbook/ch14b-config-tags-signing.md), sections 14B.1 and 14B.8 to 14B.10
- **Demo scripts.** `labs/ch14b/tag-kinds.sh`, `labs/ch14b/tag-listing.sh`, `labs/ch14b/tag-push.sh`

## HOOK

**[ON SCREEN]** "The container labelled `v1.2.0` in production does not contain the fix that the tag `v1.2.0` contains on my laptop. Which one is `v1.2.0`?"

That question comes from a CTO in a release week, and it sounds like a question about containers. It's a question about tags.

To answer it you need three facts that most engineers have never had to state. A tag is a ref, a name that holds an object ID, and every clone holds its own copy of it. Some tags are only a ref, and some are a ref plus an object. And tags don't travel the way branches do. A push, which sends your work to a server, doesn't send them unless asked. A fetch, which downloads from it, never updates one you already have.

This video gives you those three facts. The next one uses them to answer the CTO.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You met the lightweight tag in the branches part of the course: a ref under `refs/tags/` that points at a commit, one saved snapshot of the project. And you met the four object types, of which the fourth, the tag object, has had no use so far. Today it gets one.

The idea that runs through this chapter is: Git records what it is told. A tag is a name that every clone holds separately. Nothing synchronises those names behind your back. One puzzle to keep in mind: later, a single tag shows up as two lines in a listing. Why?

The project in the demonstrations is `inference-gateway`, a small service with rate limits.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- describe the refs and objects created by a lightweight, an annotated and a signed tag;
- peel a tag to its commit with `^{}`;
- list tags in version order and filter them by what they contain;
- explain which tags a fetch and a push carry;
- delete a tag and say why other clones keep it.

## CONCEPT

**[ANIMATION]** graph: 37da450-516c4c3-eb112a5 main tag:staging-2026-09-07 atag:v1.0.0#b696248; HEAD=main title=Two_tags_on_one_commit

**[ANIMATION]** step: state-1

In one sentence: a tag is a ref under `refs/tags/` that isn't expected to move. A lightweight tag points straight at a commit. An annotated tag points at a tag object that names the commit and records who tagged it, when and why. On screen, two tags from today's demo sit on one commit. What differs is behind the name.

**[ANIMATION]** end

Precisely. A tag object has four header lines and a message.

**[ON SCREEN]** The field table of section 14B.8.

| Field | Content |
|---|---|
| `object` | the ID of the object being tagged |
| `type` | its type: almost always `commit`, but `tree`, `blob` and `tag` are legal |
| `tag` | the tag's name, repeated inside the object |
| `tagger` | name, email, time and offset of the person who created the tag |
| message | free text; in a signed tag the signature block is appended to it |

**[ANIMATION]** objects: id=tagobj cards=tag:b696248:object_eb112a5+type_commit+tag_v1.0.0+tagger_Lab_User+inference-gateway_1.0.0,commit:eb112a5:tree_406c029+parent_516c4c3+Add_rate_limits,tree:406c029 refs=tag:v1.0.0>b696248,tag:staging-2026-09-07>eb112a5,main>eb112a5 title=A_ref,_or_a_ref_plus_an_object say_level_1=The_ref_v1.0.0_holds_b696248,_a_tag_object say_level_2=Peeling:_follow_the_object_line_to_the_commit_eb112a5 say_level_3=v1.0.0^{tree}_goes_one_step_further

**[ANIMATION]** step: level-1

A signed tag is an annotated tag whose text ends in a signature. So there are three kinds and two mechanisms: a bare ref, or a ref plus an object. Signatures have their own videos later. Today the signed tag is "an annotated tag with a signature block in its message".

**[ANIMATION]** step: level-3

Getting from the tag object to the commit is called peeling. `v1.0.0^{commit}` follows tag objects until it reaches a commit. `v1.0.0^{}`, with empty braces, follows them until it reaches anything that isn't a tag. Commands that want a commit, such as `git log v1.0.0`, peel for you.

**[ANIMATION]** say: git_tag_-a_writes_one_object_and_one_ref

Inside the dot git folder, `git tag -a` writes one object and one ref. No reflog is written for tags unless `core.logAllRefUpdates` is `always`. HEAD, the index and the working tree aren't involved.

**[ANIMATION]** end

Which kind when? The manual's rule: annotated tags for releases, lightweight tags for private or temporary labels. `git describe` ignores lightweight tags by default for that reason. An annotated tag also answers "who released this, and when", which the last commit's author line can't.

**Listing.** `git tag` lists in byte order, which is wrong for version numbers. `--sort=version:refname` compares the numeric parts as numbers. It still lists a pre-release after its release, because the suffix makes a longer string. `versionsort.suffix` names the suffixes that sort before the bare version.

**[ANIMATION]** graph: id=filters 37da450-516c4c3-eb112a5-ad88f54-e9fdbea-004673b-c4f3ec7-a247d58 main; eb112a5 tag:v1.2.0; ad88f54 tag:v1.9.0; e9fdbea tag:v1.10.0; 004673b tag:v2.0.0-rc.1; c4f3ec7 tag:v2.0.0-rc.2 tag:v2.0.0 tag:nightly; HEAD=main title=Filters_select_by_history,_not_by_name => + range:004673b,c4f3ec7,a247d58:--contains_HEAD~2; say:Which_tags_include_this_commit?; name:contains => + range:; range2:37da450,516c4c3,eb112a5,ad88f54:--merged_v1.9.0; say:Which_tags_are_in_the_history_of_this_one?; name:merged

Filters select by history, not by name. On screen, the tags of the second demo, each on its commit. `--contains` answers "which releases include this fix", and `--merged` answers "which releases are in the history of this commit".

**[ANIMATION]** end

**How tags travel.** Three rules.

Push sends tags only when asked. `git push origin <tag>` publishes one. `git push --follow-tags` sends, with the branch, every annotated tag that points into the commits being pushed and is missing on the server. `git push --tags` sends every tag you have, including the private ones.

Fetch follows tags. A fetch brings every tag that points into the history it downloads, of either kind, and never updates a tag you already have.

Deleting is per place. A tag lives in three places: your clone, the server, and every other clone. Each needs its own command.

**[ANIMATION]** graph: 516c4c3-eb112a5 main v1.2.0; HEAD=main => 516c4c3-eb112a5-ad88f54 main; eb112a5 v1.2.0; HEAD=main title=A_branch_moves,_a_tag_stays

**[ANIMATION]** step: state-2

When not to use a tag: as something that moves. A name that's meant to move is a branch. Watch a new commit arrive: `main` moves to it, and the tag stays.

**[ANIMATION]** end

And avoid a nested tag, a tag of a tag. The textbook calls it almost always a mistake, and Git 2.55 prints a hint when you create one.

## MENTAL MODEL

**[ANIMATION]** step: tagobj.level-3

**[ANIMATION]** say: A_sticky_note_on_the_page,_and_a_certificate_that_cites_it

The textbook's analogy uses the ledger. A lightweight tag is a sticky note on a page of the ledger. An annotated tag is a certificate that cites the page number and is filed in the ledger with a page number of its own.

**[ANIMATION]** say: Two_IDs:_b696248_is_the_certificate,_eb112a5_the_page_it_cites

That's why an annotated tag has two IDs to keep apart: the ID of the certificate, which is what the ref holds, and the ID of the page it cites, the commit.

**[ANIMATION]** say: The_tagger_line_is_text_supplied_by_whoever_created_the_tag

The analogy breaks because nobody certifies anything unless the tag is also signed. The tagger line of an annotated tag is text supplied by whoever created it, the same as an author line.

**[ANIMATION]** end

Add one thing for travel: every clone has its own set of sticky notes and its own copies of the certificates. Handing someone the ledger doesn't hand over your notes unless you say so, and once they have a note with a given name, they keep theirs.

## DIAGRAM

Try it now, on paper. Pause me for thirty seconds and draw your answer: a commit, a lightweight tag and an annotated tag.

**[PAUSE]**

**[DIAGRAM]** The picture of section 14B.8. Draw the commit first, then the lightweight tag, then the annotated tag with its object.

```text
  refs/tags/staging-2026-09-07 ----------------------------+
                                                           v
  refs/tags/v1.0.0 --> tag b696248                  commit eb112a5 <-- refs/heads/main <-- HEAD
                       object eb112a5 --------------^      |
                       type   commit                       v
                       tag    v1.0.0                   tree 406c029
                       tagger Lab User ... +0530
                       "inference-gateway 1.0.0"
```

The top arrow is the lightweight tag: ref to commit, nothing between. The lower path is the annotated tag: the ref holds `b696248`, the tag object, and the tag object's `object` line holds the commit `eb112a5`. Peeling is walking the lower path to its end.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14b/tag-kinds`. 🟢 SAFE: creating a tag adds one ref, and with `-a` one object.

```bash
git log --oneline
git tag staging-2026-09-07
cat .git/refs/tags/staging-2026-09-07
git cat-file -t staging-2026-09-07
git count-objects | cut -d, -f1
```

<!-- snippet: ch14b/tag-kinds/01-lightweight -->
```text
$ git log --oneline
eb112a5 Add rate limits
516c4c3 Add model router
37da450 Add README
$ git tag staging-2026-09-07
$ cat .git/refs/tags/staging-2026-09-07
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
$ git cat-file -t staging-2026-09-07
commit
$ git count-objects | cut -d, -f1
11 objects
```
<!-- /snippet -->

The ref file holds the commit ID. The type is `commit`. Eleven objects. Predict the object count after an annotated tag. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."
git count-objects | cut -d, -f1
cat .git/refs/tags/v1.0.0
git cat-file -t v1.0.0
git cat-file -p v1.0.0
```

<!-- snippet: ch14b/tag-kinds/02-annotated -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."
$ git count-objects | cut -d, -f1
12 objects
$ cat .git/refs/tags/v1.0.0
b69624883fa40e51cbbf4c4baf49365ba1caa02e
$ git cat-file -t v1.0.0
tag
$ git cat-file -p v1.0.0
object eb112a5c44b0b2092c4ef2cae6e75b16da000f73
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788756060 +0530

inference-gateway 1.0.0

First release with rate limits.
```
<!-- /snippet -->

Twelve. The ref holds `b696248`, and that object's type is `tag`. Read its four header lines against the table. Now peel it.

```bash
git rev-parse v1.0.0 'v1.0.0^{tag}' 'v1.0.0^{commit}' 'v1.0.0^{}' 'v1.0.0^{tree}'
git show-ref --tags --dereference
```

<!-- snippet: ch14b/tag-kinds/03-peel -->
```text
$ git rev-parse v1.0.0 'v1.0.0^{tag}' 'v1.0.0^{commit}' 'v1.0.0^{}' 'v1.0.0^{tree}'
b69624883fa40e51cbbf4c4baf49365ba1caa02e
b69624883fa40e51cbbf4c4baf49365ba1caa02e
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
406c0291b052f665e4581982583c94937f169d80
$ git show-ref --tags --dereference
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/staging-2026-09-07
b69624883fa40e51cbbf4c4baf49365ba1caa02e refs/tags/v1.0.0
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/v1.0.0^{}
$ git for-each-ref refs/tags --format='%(refname:short) | %(objecttype) %(objectname:short) | peeled: %(*objecttype) %(*objectname:short)'
staging-2026-09-07 | commit eb112a5 | peeled:  
v1.0.0 | tag b696248 | peeled: commit eb112a5
```
<!-- /snippet -->

The name alone and `^{tag}` give the tag object. `^{commit}` and `^{}` give `eb112a5`. In `git show-ref --dereference`, and in `git ls-remote`, the line ending in `^{}` is the peeled value of the line above. You'll read that pair of lines many times.

A tag can name an older commit, and `-m` alone implies `-a`.

```bash
git tag -a v0.9.0 -m "Internal preview" HEAD~1
git tag -m "Rate limits verified on staging" v1.0.0-verified
git tag -n1
git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(creatordate:iso)'
```

<!-- snippet: ch14b/tag-kinds/05-older-commit -->
```text
$ git tag -a v0.9.0 -m "Internal preview" HEAD~1
$ git tag -m "Rate limits verified on staging" v1.0.0-verified
$ git tag -n1
staging-2026-09-07 Add rate limits
v0.9.0          Internal preview
v1.0.0          inference-gateway 1.0.0
v1.0.0-verified Rate limits verified on staging
$ git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(creatordate:iso)'
staging-2026-09-07 commit 2026-09-07 10:05:00 +0530
v0.9.0 tag 2026-09-07 10:21:00 +0530
v1.0.0 tag 2026-09-07 10:11:00 +0530
v1.0.0-verified tag 2026-09-07 10:22:00 +0530
```
<!-- /snippet -->

Look at the dates: `v0.9.0` names an older commit and carries a later date than `v1.0.0`. The tagger date is the moment of tagging, not of the commit.

A tag can also name a blob, a tree or another tag.

```bash
git tag -a limits-schema-v1 -m "Limits file format, version 1" HEAD:config/limits.yaml
git cat-file -p limits-schema-v1 | head -3
git tag -a v1.0.0-audited -m "Audit ticket SEC-88 closed" v1.0.0
```

<!-- snippet: ch14b/tag-kinds/06-not-a-commit -->
```text
# A tag can name any object. Here: one blob, the limits file as released, and then a tag of a tag.
$ git tag -a limits-schema-v1 -m "Limits file format, version 1" HEAD:config/limits.yaml
$ git cat-file -p limits-schema-v1 | head -3
object cb775a8efb9ad28e94389151972d6b06a5b263ee
type blob
tag limits-schema-v1
$ git tag -a v1.0.0-audited -m "Audit ticket SEC-88 closed" v1.0.0
hint: You have created a nested tag. The object referred to by your new tag is
hint: already a tag. If you meant to tag the object that it points to, use:
hint:
hint: 	git tag -f v1.0.0-audited v1.0.0^{}
hint: Disable this message with "git config set advice.nestedTag false"
$ git cat-file -p v1.0.0-audited | head -3
object b69624883fa40e51cbbf4c4baf49365ba1caa02e
type tag
tag v1.0.0-audited
$ git rev-parse v1.0.0-audited 'v1.0.0-audited^{tag}' 'v1.0.0-audited^{}'
6b410c8476aa6fcc8612bdcee3310b2654ae803d
6b410c8476aa6fcc8612bdcee3310b2654ae803d
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
```
<!-- /snippet -->

"type blob" in the first. And for the second, Git's hint: you have created a nested tag.

Names obey the ref-name rules.

<!-- snippet: ch14b/tag-kinds/07-names -->
```text
$ git tag "v1.0 final"
fatal: 'v1.0 final' is not a valid tag name.
[exit status: 128]
$ git tag v1.0.0
fatal: tag 'v1.0.0' already exists
[exit status: 128]
$ git check-ref-format refs/tags/v1.0.0+build.7
[exit status: 0]
$ git check-ref-format "refs/tags/v1.0.0~1"
[exit status: 1]
```
<!-- /snippet -->

No spaces, no tilde, caret or colon. The plus sign of a build-metadata suffix is allowed. And an existing tag name is refused: Git doesn't move a tag unless you force it.

**[TERMINAL]** Replay `labs/run ch14b/tag-listing`.

```bash
git log --oneline --decorate
git tag
```

<!-- snippet: ch14b/tag-listing/01-default-order -->
```text
$ git log --oneline --decorate
a247d58 (HEAD -> main) Document streaming
c4f3ec7 (tag: v2.0.0-rc.2, tag: v2.0.0, tag: nightly) Fix stream flush
004673b (tag: v2.0.0-rc.1) Add streaming responses
e9fdbea (tag: v1.10.0) Add token check
ad88f54 (tag: v1.9.0) Add health endpoint
eb112a5 (tag: v1.2.0) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git tag
nightly
v1.10.0
v1.2.0
v1.9.0
v2.0.0
v2.0.0-rc.1
v2.0.0-rc.2
```
<!-- /snippet -->

Byte order: `v1.10.0` before `v1.2.0`. Predict where `v2.0.0-rc.1` lands with a version sort. Say it out loud.

```bash
git tag --sort=version:refname
git -c versionsort.suffix=-rc tag --sort=version:refname
```

<!-- snippet: ch14b/tag-listing/02-version-sort -->
```text
$ git tag --sort=version:refname
nightly
v1.2.0
v1.9.0
v1.10.0
v2.0.0
v2.0.0-rc.1
v2.0.0-rc.2
$ git -c versionsort.suffix=-rc tag --sort=version:refname
nightly
v1.2.0
v1.9.0
v1.10.0
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
```
<!-- /snippet -->

After `v2.0.0`, which is wrong for a release candidate, until `versionsort.suffix` names the suffix. Both settings can be made the default. 🟡 CAUTION: `git config set` writes a key into `.git/config` and changes what later commands print. It needs Git 2.46 or later.

```bash
git config set tag.sort version:refname
git config set versionsort.suffix -rc
git tag --list 'v2.*'
git tag --list 'v[0-9]*' --sort=-version:refname | head -1
```

<!-- snippet: ch14b/tag-listing/03-configured -->
```text
$ git config set tag.sort version:refname
$ git config set versionsort.suffix -rc
$ git tag --list 'v2.*'
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
$ git tag --list 'v[0-9]*' --sort=-version:refname | head -1
v2.0.0
```
<!-- /snippet -->

The last command is the usual scripted answer to "what is the newest release". Now the filters.

```bash
git tag --contains HEAD~2
git tag --no-contains HEAD~2
git tag --points-at HEAD~1
```

<!-- snippet: ch14b/tag-listing/04-filters -->
```text
$ git tag --contains HEAD~2
nightly
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
$ git tag --no-contains HEAD~2
v1.2.0
v1.9.0
v1.10.0
$ git tag --points-at HEAD~1
nightly
v2.0.0-rc.2
v2.0.0
$ git tag --merged v1.9.0
v1.2.0
v1.9.0
```
<!-- /snippet -->

`--contains` is the one you'll use in incidents: which releases include this commit.

**[TERMINAL]** Replay `labs/run ch14b/tag-push`. Three clones: yours, the server, and Asha's. Tag a release, commit, push. Predict what the server's tag list shows.

```bash
git tag -a v1.0.0 -m "inference-gateway 1.0.0"
git push
git ls-remote --tags origin
```

<!-- snippet: ch14b/tag-push/01-not-pushed -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0"
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -am "Allow short bursts"
$ git push
To ../../server/inference-gateway.git
   d20ef7a..fa279e8  main -> main
$ git ls-remote --tags origin
```
<!-- /snippet -->

**[ANIMATION]** remotes: id=travel title=A_push_sends_tags_only_when_asked [your clone] ...older-d20ef7a-fa279e8 main origin/main; d20ef7a atag:v1.0.0#3caaa39; HEAD=main; cmd:git_push; say:The_branch_went,_the_tag_did_not || [origin] ...older-d20ef7a-fa279e8 main; HEAD=none => || + d20ef7a atag:v1.0.0#3caaa39; cmd:git_push_origin_v1.0.0; say:One_tag,_pushed_by_name; name:one => [your clone] ...older-d20ef7a-fa279e8-46cb046 main origin/main; d20ef7a atag:v1.0.0#3caaa39; fa279e8 atag:v1.0.1#65ad079 tag:canary-ok; 46cb046 tag:wip-retry-header; HEAD=main; cmd:git_push_--follow-tags; say:Only_the_annotated_tag_follows_the_branch; name:third || [origin] ...older-d20ef7a-fa279e8-46cb046 main; d20ef7a atag:v1.0.0#3caaa39; fa279e8 atag:v1.0.1#65ad079; HEAD=none

**[ANIMATION]** step: state-1

Nothing. The branch went. The tag didn't. Almost everyone is caught by this once.

**[ON SCREEN]** 🟡 CAUTION: `git push origin <tag>`. It creates `refs/tags/<tag>` on the remote. Lower third: **GitHub**: the tag appears there, and a ruleset may refuse it.

```bash
git push origin v1.0.0
git ls-remote --tags origin
```

<!-- snippet: ch14b/tag-push/02-push-one -->
```text
$ git push origin v1.0.0
To ../../server/inference-gateway.git
 * [new tag]         v1.0.0 -> v1.0.0
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
```
<!-- /snippet -->

**[ANIMATION]** step: travel.one

Two lines for one tag: the tag object `3caaa39`, and the peeled line with the commit `d20ef7a`. That's the puzzle from the start, solved.

**[ANIMATION]** end

Now one annotated tag and two lightweight ones, and `--follow-tags`. Quick quiz: which of the three go? Option one: all three. Option two: only the annotated one. Option three: none. Say it out loud.

**[PAUSE]**

<!-- snippet: ch14b/tag-push/03-follow-tags -->
```text
$ git tag -a v1.0.1 -m "inference-gateway 1.0.1"
$ git tag canary-ok
$ printf 'retry_after_seconds: 2\n' >> config/limits.yaml
$ git commit -q -am "Tell clients when to retry"
$ git tag wip-retry-header
$ git push --follow-tags
To ../../server/inference-gateway.git
   fa279e8..46cb046  main -> main
 * [new tag]         v1.0.1 -> v1.0.1
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
65ad079e6bee92a0439fecf06a757ee24052b697	refs/tags/v1.0.1
fa279e82e36171f73f18c59df2c68bef182e5601	refs/tags/v1.0.1^{}
```
<!-- /snippet -->

**[ANIMATION]** step: travel.third

Option two. `v1.0.1` went. The lightweight tags `canary-ok` and `wip-retry-header` stayed, which is the point of `--follow-tags`.

Asha fetches.

```bash
git fetch
git tag
```

<!-- snippet: ch14b/tag-push/04-colleague-fetches -->
```text
$ cd ../../asha/inference-gateway
$ git fetch
From ../../server/inference-gateway
   d20ef7a..46cb046  main       -> origin/main
 * [new tag]         v1.0.0     -> v1.0.0
 * [new tag]         v1.0.1     -> v1.0.1
$ git tag
v1.0.0
v1.0.1
```
<!-- /snippet -->

Both tags arrived without being asked for, because they point into the history she downloaded.

Deleting. Three places.

**[ON SCREEN]** 🟡 CAUTION: `git tag -d` removes your ref. 🔴 DANGEROUS: `git push origin --delete <tag>`. What it changes: the server's tag ref is deleted. What it can destroy: the published name of a release; on GitHub, a release built on the tag is affected. Preview: `git ls-remote --tags origin`. Recovery: push it again from a clone that kept it. Appropriate: for a tag pushed by mistake minutes ago, and announced.

```bash
git tag -d canary-ok
git push origin --delete v1.0.1
git ls-remote --tags origin
git tag
```

<!-- snippet: ch14b/tag-push/05-delete -->
```text
$ cd ../../you/inference-gateway
$ git tag -d canary-ok
Deleted tag 'canary-ok' (was fa279e8)
$ git push origin --delete v1.0.1
To ../../server/inference-gateway.git
 - [deleted]         v1.0.1
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
$ git tag
v1.0.0
v1.0.1
wip-retry-header
```
<!-- /snippet -->

The server no longer has `v1.0.1`. Your local `v1.0.1` is still there. And Asha's?

**[ON SCREEN]** 🔴 DANGEROUS: `git fetch --prune --prune-tags`. What it changes: it makes your tags equal to the server's. What it can destroy: every local tag the server does not have, including private ones. Preview: add `--dry-run`. Recovery: for annotated tags, `git fsck` lists the dangling tag object; for lightweight tags, only what the command printed, and tags have no reflog. Appropriate: for a mirror or a CI cache that must equal the server.

```bash
git tag bisect-good-2026-09-07 HEAD~1
git fetch --prune
git tag
git fetch --prune --prune-tags
git tag
```

<!-- snippet: ch14b/tag-push/06-other-clones-keep-it -->
```text
$ cd ../../asha/inference-gateway
$ git tag bisect-good-2026-09-07 HEAD~1
$ git fetch --prune
$ git tag
bisect-good-2026-09-07
v1.0.0
v1.0.1
$ git fetch --prune --prune-tags
From ../../server/inference-gateway
 - [deleted]         (none)     -> bisect-good-2026-09-07
 - [deleted]         (none)     -> v1.0.1
$ git tag
v1.0.0
```
<!-- /snippet -->

**[ANIMATION]** remotes: id=places title=Deleting_is_per_place [origin] ...older-d20ef7a-fa279e8-46cb046 main; d20ef7a atag:v1.0.0#3caaa39; HEAD=none; say:git_fetch_--prune_does_not_touch_tags:_Asha_keeps_v1.0.1 || [Asha's clone] ...older-d20ef7a-fa279e8-46cb046 origin/main; d20ef7a main; d20ef7a atag:v1.0.0#3caaa39; fa279e8 atag:v1.0.1#65ad079; HEAD=main => || [Asha's clone] ...older-d20ef7a-fa279e8-46cb046 origin/main; d20ef7a main; d20ef7a atag:v1.0.0#3caaa39; HEAD=main; cmd:git_fetch_--prune_--prune-tags; say:Only_--prune-tags_removes_her_copy; name:tagsgone

`git fetch --prune` doesn't touch tags: Asha keeps `v1.0.1`. `--prune-tags` deleted it, and deleted her private `bisect-good-2026-09-07` with it. Note the "(none)" in the output: no old ID is printed. And remember the other direction: a deleted tag that someone still holds comes back with their next `git push --tags`.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"I pushed, so the release tag is on the server."** Root cause: a push sends tags only when asked; the branch update does not carry them.
2. **Comparing a tag's ID with a commit ID and finding a mismatch.** Root cause: the ref of an annotated tag holds the ID of the tag object; the commit is the peeled value, `^{}`.
3. **Finding the newest release with plain `git tag | tail -1`.** Root cause: the default order is byte order, in which `v1.10.0` sorts before `v1.2.0`.
4. **`git push --tags` from a working clone.** Root cause: it sends every tag you have, including private and temporary ones.
5. **Deleting a tag on the server and assuming it is gone.** Root cause: every clone holds its own copy, a plain fetch never removes it, and anyone's `git push --tags` brings it back.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML team tags the commit that produced each published model with an annotated tag such as `model/reranker/2026-09-07`, and writes the evaluation run ID into the message. Two years later `git show` on that tag still says which code, who released it and which evaluation justified it.

The team's release script uses `git push --follow-tags`, so the annotated release tag goes with the branch and the engineers' private lightweight tags, for bisecting and for marking a canary, stay on their machines. Nobody in the team runs `git push --tags`.

## PRACTICE EXERCISE

Your turn. Do Lab 13.1, "Three kinds of tag", in [`lab-manual/m13-tags-versions.md`](../../lab-manual/m13-tags-versions.md).

Before you create each tag, predict how many objects the repository will have afterwards, what the ref file will contain, and what `git cat-file -t` will say for the tag name. Before you peel, predict which of the five revision expressions print the same ID.

The challenge is Exercise 13.5, Level 2, command prediction, "What a tag name resolves to", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q94: "Describe the objects and refs created by `git tag v1`, `git tag -a v1` and `git tag -s v1`. What does `v1^{}` resolve to in each case?"

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** replay: tagobj

A strong answer counts: how many refs and how many new objects each command writes, and what each ref holds. It names the fields of the tag object and says where the signature of a signed tag lives. It defines peeling in one sentence and applies it to all three cases, including the one where there is nothing to peel. And it adds one consequence that shows understanding, for example what you see in `git ls-remote` for each kind, or why one kind is ignored by `git describe` by default.

## RECAP

Let's land this. You should now be able to say:

- A lightweight tag is a ref to a commit; an annotated tag is a ref to a tag object that names the commit, the tagger, the date and a message; a signed tag is an annotated tag with a signature.
- `^{}` peels a tag to the object it finally names.
- `--sort=version:refname` with `versionsort.suffix` lists versions in the right order, and `--contains` tells me which releases include a commit.
- A push sends tags only when asked; a fetch brings tags that point into fetched history and never updates one I have.
- A tag lives in three places, and deleting it in one leaves the others.

## HOMEWORK

Read sections 14B.8 to 14B.10 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md). Do Exercises 13.1 to 13.3, Level 1, "Two kinds of tag, counted in objects", "Listing and sorting" and "Which tags travel", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you took a tag apart: one ref, sometimes one object, and three places it lives. Create a lightweight and an annotated tag in the lab, and peel both. Next time: why a published tag must not move. Until then, look at the state first and type second. See you in the next one.

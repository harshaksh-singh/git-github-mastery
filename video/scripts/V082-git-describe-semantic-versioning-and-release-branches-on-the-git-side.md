# V082: git describe, Semantic Versioning, and release branches on the Git side

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 13, Tags and versions
- **Planned minutes.** 22
- **Prerequisites.** V063, V081
- **Textbook sections.** [Chapter 14B](../../textbook/ch14b-config-tags-signing.md), sections 14B.12 to 14B.14
- **Demo scripts.** `labs/ch14b/describe.sh`, `labs/ch14b/describe-shallow.sh`, `labs/ch14b/release-branch.sh`

## HOOK

**[ON SCREEN]** On the laptop: `v1.0.0-2-g72212ba`. In CI: `fatal: No names found, cannot describe anything.`

The service prints its version at start-up. The build derives that version from Git. On every developer machine the build produces a version string that makes sense. In CI, the automated build pipeline, it's the same commit and the same build script, and the version is either a bare fallback or the job fails.

Nothing is wrong with the repository on the server. Nothing is wrong with the build script. The CI checkout has one commit and no tags, and a version computed from history can't be computed without the history.

A second question follows it into the incident channel: "Version 1.2.1 has been released. Why does `main` still call itself 1.2.0-plus-three?" Keep that one in mind. It has a tidy answer.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You now know what a tag is, a ref that isn't expected to move, and why a published one doesn't move. Today you put tags to work in three ways. `git describe` turns history into a version string. Semantic Versioning is the convention most projects put on tag names. Git itself attaches no meaning to them. And a release branch is how an old version receives fixes without receiving features.

All three meet in one production question: which releases contain this fix?

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- read every part of a `git describe` string;
- explain why describe fails or prints a different answer in a shallow clone;
- state the Semantic Versioning rules the section gives;
- cut a release branch from a tag, backport a fix, and tag a patch release;
- answer "which releases contain this fix" with tags.

## CONCEPT

**`git describe`.** In one sentence: 🟢 SAFE, `git describe` names a commit by the nearest annotated tag in its history, the number of commits since that tag, and the commit's abbreviated ID. An annotated tag is the kind with its own tag object: a tagger, a date and a message.

**[ANIMATION]** graph: id=desc title=A_tag,_a_count,_an_ID 37da450-516c4c3-eb112a5 main atag:v1.0.0; HEAD=main; cmd:git_describe; say:On_the_tagged_commit,_the_output_is_the_tag_name:_v1.0.0 => 37da450-516c4c3-eb112a5-f37f723-c053f0d main; eb112a5 atag:v1.0.0; HEAD=main; range:f37f723,c053f0d:2_commits_since_the_tag; cmd:git_describe; say:v1.0.0-2-gc053f0d

**[ANIMATION]** step: state-1

Precisely. If a tag points at the commit, the output is the tag name.

**[ANIMATION]** step: state-2

Otherwise Git walks back through history, finds tagged ancestors, picks the one with the fewest commits between it and the commit, and prints tag, hyphen, count, hyphen, the letter g, and the abbreviated ID. The g stands for "git". On screen that's `v1.0.0`, two commits, and `c053f0d`. Lightweight tags are ignored unless you pass `--tags`.

**[ANIMATION]** say: The_whole_string_is_also_a_valid_revision

The whole string is also a valid revision. A version printed by a running service can be pasted into `git show`.

**[ANIMATION]** end

Options you'll use. `--dirty` appends a mark when tracked files differ from HEAD, so a build from a modified working tree can't pass as a release. `--match` and `--exclude` take globs and decide which tags may be used. `--abbrev=0` prints only the nearest tag. `--long` always prints the full form. `--exact-match` fails unless the commit itself is tagged. `--first-parent` ignores tags that arrived through merged branches. `--always` falls back to the abbreviated ID. And `--contains` asks the other direction: which tag comes after this commit.

**[ANIMATION]** shallow: id=shallow title=What_a_shallow_clone_lacks ...older-*1-*2-72212ba main; *1 atag:v1.0.0; HEAD=main; say:A_full_clone:_v1.0.0-2-g72212ba => ...older-*1-*2-72212ba main; HEAD=main; absent:...older,*1,*2; cmd:git_clone_--depth_1; say:Depth_1:_one_commit_and_no_tags; name:depth => ...older-*1-*2-72212ba main; *1 atag:v1.0.0; HEAD=main; absent:...older,*2; cmd:git_fetch_--depth_1_origin_tag_v1.0.0; say:The_tag_is_here,_the_commit_between_is_not:_nothing_to_count; name:tagonly => ...older-*1-*2-72212ba main; *1 atag:v1.0.0; HEAD=main; cmd:git_fetch_--unshallow; say:Full_history_again:_v1.0.0-2-g72212ba; name:unshallow

**[ANIMATION]** step: depth

It fails in three ways. No tags at all. Only lightweight tags. And a shallow clone, a clone that was given only the newest part of the history. The third is the common one in CI. A depth-1 clone has one commit and no tags. Fetching the tag isn't enough, because the commits between the tag and the tip are still missing, and Git can't count them.

**Semantic Versioning 2.0.0.** Git attaches no meaning to a tag name. This is the convention on top.

**[ON SCREEN]** The rules as section 14B.13 gives them.

A version is MAJOR, MINOR, PATCH. Incompatible API changes raise MAJOR. Backward-compatible additions raise MINOR. Backward-compatible fixes raise PATCH. A released version is immutable: its contents "MUST NOT be modified". Any change is a new version. That's the rule of the previous video, stated for packages.

Zero-dot versions are initial development, where anything may change. A pre-release is marked by a hyphen and dot-separated identifiers, and has lower precedence than the release. Numeric identifiers compare as numbers, so `rc.2` is before `rc.11`. Build metadata follows a plus sign and is ignored when versions are compared. And the specification's FAQ says that `v1.2.3` is not itself a semantic version. The `v` prefix is a common way to mark a tag as a version.

Three consequences for Git. The pre-release rule is why you needed `versionsort.suffix` when listing tags. The output of `git describe` is not a valid semantic version of a later build, because by the pre-release rule it would sort before the release it names. Tools that publish packages translate it into their ecosystem's format. And SemVer describes a public API. For a service that nobody links against, a date-based scheme carries the same information with less ceremony.

**[ANIMATION]** graph: id=rel dx=230 title=A_release_branch_starts_at_a_tag 37da450-516c4c3-eb112a5-27d1fb6-362b359-8ed5c59 main; eb112a5 atag:v1.2.0; HEAD=main => + eb112a5 release/1.2; HEAD=release/1.2; cmd:git_switch_-c_release/1.2_v1.2.0; name:branch => + eb112a5-c40960e release/1.2 atag:v1.2.1; cmd:git_cherry-pick_-x_main~1; name:backport => + same:362b359; same:c40960e; cmd:git_cherry_-v_release/1.2_main; say:One_fix,_two_commits,_two_IDs; name:copies => 37da450-516c4c3-eb112a5-27d1fb6-362b359-8ed5c59 main; eb112a5 atag:v1.2.0; eb112a5-c40960e release/1.2 atag:v1.2.1; HEAD=release/1.2; same:362b359; same:c40960e; range:27d1fb6,362b359,8ed5c59:v1.2.0..main; cmd:git_describe_main; say:v1.2.0-3-g8ed5c59:_v1.2.1_is_not_an_ancestor_of_main; name:three => 37da450-516c4c3-eb112a5-27d1fb6-362b359-8ed5c59 main; eb112a5 atag:v1.2.0; eb112a5-c40960e release/1.2 atag:v1.2.1; 8ed5c59 atag:v1.3.0; HEAD=main; cmd:git_describe_main; say:Now_main_describes_itself_as_v1.3.0; name:minor

**[ANIMATION]** step: state-1

**Release branches, on the Git side.** When more than one version is in use, a tag isn't enough: the old version needs fixes that must not bring new features with them.

**[ANIMATION]** step: backport

A release branch is an ordinary branch that starts at the release tag. Fixes arrive on it, and each patch release is a tag on it.

There are two conventions for the direction of a fix. The Git project fixes on the oldest maintained branch and merges upward. Trunk-based practice fixes on the main line and cherry-picks to the release branch, which is what the demonstration does. A cherry-pick copies one commit's change as a new commit. The team-workflows part of the course discusses the choice.

**[ANIMATION]** step: copies

The failure mode to expect: after a backport by cherry-pick, the fix exists as two commits with two IDs. On screen, `362b359` on `main` and its copy `c40960e` on the release branch. No tag on the release branch contains the original commit. Questions about content need the tools that compare patches.

**[ANIMATION]** end

## MENTAL MODEL

**[ANIMATION]** step: desc.state-2

**[ANIMATION]** say: From_the_signpost_v1.0.0,_two_commits_forward,_to_c053f0d

Read a describe string as a set of directions. "From the signpost named `v1.0.0`, walk two commits forward, and you should be standing at the commit whose ID begins `c053f0d`." The signpost is an annotated tag. The distance is a count along history. The last part confirms that you arrived at the right place.

**[ANIMATION]** step: shallow.depth

**[ANIMATION]** say: A_shallow_clone:_no_signpost_in_view,_no_road_walked

The directions can only be written by someone who can see the signpost and the road between it and where they stand. A shallow clone is a traveller who was dropped at the destination by helicopter: no signpost in view, no road walked.

**[ANIMATION]** step: rel.copies

**[ANIMATION]** say: A_signpost_on_a_side_road:_v1.2.1_is_invisible_from_main

And describe only ever looks backward. A signpost on a side road that you didn't come along, such as a tag on a release branch, is invisible from `main`.

**[ANIMATION]** end

Where the model breaks: "nearest" isn't about dates. It is the tagged ancestor with the fewest commits between it and you.

## DIAGRAM

Try it now, on paper. Pause me for thirty seconds. Draw five commits in a row, put an annotated tag on the third, and write your answer: the describe string for the fifth.

**[PAUSE]**

**[DIAGRAM]** A describe string split into its three parts, with an arrow from each to the graph. Use the IDs of the transcript.

```text
            v1.0.0  -  2  -  g c053f0d
              |        |        |
              |        |        +--> the abbreviated ID of the described commit ("g" for git)
              |        +-----------> commits between the tag and that commit
              +--------------------> the nearest annotated tag in its history

  37da450---516c4c3---eb112a5---f37f723---c053f0d      main  (HEAD)
                      (tag: v1.0.0)   1        2
```

Count the two commits after the tag on the graph: `f37f723` is one, `c053f0d` is two.

**[ON SCREEN]** The root-cause box of section 14B.12, shown when the demonstration reaches the shallow clone.

```text
Observed behavior : the build in CI gets a fallback version or fails; locally the version is v1.0.0-2-g72212ba.
Git state         : the CI checkout is shallow (one commit) and has no refs/tags/.
Mechanism         : git describe needs a tagged ancestor and the commits between it and HEAD.
Root cause        : the checkout step fetched one commit; tools that derive versions from tags
                    (git describe, setuptools-scm and similar) fall back or fail.
Why Git does this : a shallow clone is a deliberate trade of history for speed.
Correct fix       : fetch full history and tags in jobs that compute a version.
Prevention        : make the release job fail when git describe --exact-match fails.
```

Here is the failure from the opening as a root-cause box. Read the mechanism line: describe needs a tagged ancestor and the commits between it and HEAD.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14b/describe`. Start with the failures, because they define the command. No tags; then a lightweight tag only.

```bash
git describe
git describe --always
git tag staging-ok
git describe
git describe --tags
```

<!-- snippet: ch14b/describe/01-no-tags -->
```text
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
eb112a5
$ git tag staging-ok
$ git describe
fatal: No annotated tags can describe 'eb112a5c44b0b2092c4ef2cae6e75b16da000f73'.
However, there were unannotated tags: try --tags.
[exit status: 128]
$ git describe --tags
staging-ok
```
<!-- /snippet -->

"No names found". Then, with a lightweight tag: "No annotated tags can describe", and a pointer to `--tags`. Now an annotated tag on the current commit.

<!-- snippet: ch14b/describe/02-on-the-tag -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0"
$ git describe
v1.0.0
$ git describe --long
v1.0.0-0-geb112a5
```
<!-- /snippet -->

On the tag, the output is the tag name. `--long` shows the full form with a count of zero. Two commits later, predict the string. Say it out loud. I'll wait.

**[PAUSE]**

```bash
git log --oneline --decorate
git describe
git rev-parse --short HEAD
git rev-list --count v1.0.0..HEAD
```

<!-- snippet: ch14b/describe/03-after-the-tag -->
```text
$ git log --oneline --decorate
c053f0d (HEAD -> main) Add token check
f37f723 Add health endpoint
eb112a5 (tag: v1.0.0, tag: staging-ok) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git describe
v1.0.0-2-gc053f0d
$ git rev-parse --short HEAD
c053f0d
$ git rev-list --count v1.0.0..HEAD
2
$ git log --oneline "$(git describe)" -1
c053f0d Add token check
```
<!-- /snippet -->

`v1.0.0-2-gc053f0d`. The count is the size of the range from the tag to HEAD, and the last part is the abbreviated ID after the g.

```bash
git describe --abbrev=0
git describe --abbrev=12
git describe HEAD~1
git describe --exact-match
git describe --exact-match HEAD~2
```

<!-- snippet: ch14b/describe/04-options -->
```text
$ git describe --abbrev=0
v1.0.0
$ git describe --abbrev=12
v1.0.0-2-gc053f0d37c02
$ git describe HEAD~1
v1.0.0-1-gf37f723
$ git describe --exact-match
fatal: no tag exactly matches 'c053f0d37c02869f5920caf5d1f46b9fa6270dbc'
[exit status: 128]
$ git describe --exact-match HEAD~2
v1.0.0
```
<!-- /snippet -->

`--exact-match` fails on an untagged commit with exit status 128. Keep that: it's the check a release job should make.

```bash
git describe --dirty
git describe --dirty=+local
git restore gateway/auth.py
git describe --dirty
```

<!-- snippet: ch14b/describe/05-dirty -->
```text
$ printf 'def check(token):\n    return token == "letmein"\n' > gateway/auth.py
$ git describe --dirty
v1.0.0-2-gc053f0d-dirty
$ git describe --dirty=+local
v1.0.0-2-gc053f0d+local
$ git restore gateway/auth.py
$ git describe --dirty
v1.0.0-2-gc053f0d
```
<!-- /snippet -->

A modified tracked file adds "-dirty". After the file is restored, the mark is gone. `git restore` on a path is 🔴 DANGEROUS in general, because it overwrites the working-tree file and uncommitted edits to it can't be recovered. Here the script discards an edit it made itself. Twig looks worried, and with a red label on screen, fairly so.

Which tags may be used? Add a release candidate one commit back and a lightweight tag on HEAD.

```bash
git tag -a v1.1.0-rc.1 -m "Release candidate" HEAD~1
git tag deployed-staging
git describe
git describe --exclude '*-rc.*'
git describe --tags
git describe --tags --match 'v[0-9]*'
```

<!-- snippet: ch14b/describe/06-which-tags -->
```text
$ git tag -a v1.1.0-rc.1 -m "Release candidate" HEAD~1
$ git tag deployed-staging
$ git describe
v1.1.0-rc.1-1-gc053f0d
$ git describe --exclude '*-rc.*'
v1.0.0-2-gc053f0d
$ git describe --tags
deployed-staging
$ git describe --tags --match 'v[0-9]*'
v1.1.0-rc.1-1-gc053f0d
```
<!-- /snippet -->

The nearest annotated tag is now the release candidate. `--exclude` skips it. `--tags` admits the lightweight tag, and `--match` restricts to version-shaped names. Decide these options once, in the build script, and write them down: two builds with different options print different versions for the same commit.

**[TERMINAL]** Replay `labs/run ch14b/describe-shallow`. In a full clone:

<!-- snippet: ch14b/describe-shallow/01-full-clone -->
```text
$ git describe
v1.0.0-2-g72212ba
```
<!-- /snippet -->

Now the CI checkout: a clone with `--depth 1`. Predict what `git tag` and `git describe` print.

```bash
git clone -q --depth 1 "file://$PWD/server/inference-gateway.git" ci/inference-gateway
git rev-parse --is-shallow-repository
git log --oneline
git tag
git describe
git describe --always
```

<!-- snippet: ch14b/describe-shallow/02-shallow -->
```text
$ cd ../..
$ git clone -q --depth 1 "file://$PWD/server/inference-gateway.git" ci/inference-gateway
$ cd ci/inference-gateway
$ git rev-parse --is-shallow-repository
true
$ git log --oneline
72212ba Add token check
$ git tag
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
72212ba
```
<!-- /snippet -->

One commit, no tags, "No names found". The tempting fix is to fetch the tag. Quick quiz, two options. One: with the tag fetched, describe works. Two: it still fails. Say it out loud.

**[PAUSE]**

```bash
git fetch -q --depth 1 origin tag v1.0.0
git tag
git describe
```

<!-- snippet: ch14b/describe-shallow/03-tags-without-history -->
```text
$ git fetch -q --depth 1 origin tag v1.0.0
$ git tag
v1.0.0
$ git describe
fatal: No tags can describe '72212bae7bd9bd85bd7300a9a92d9f8d50f89807'.
Try --always, or create some tags.
[exit status: 128]
```
<!-- /snippet -->

**[ANIMATION]** step: shallow.tagonly

Option two. The tag is there, and describe still fails: "No tags can describe". The commits between the tag and the tip are missing, so the tag isn't a known ancestor and nothing can be counted. Almost everyone tries this fix first.

```bash
git fetch --unshallow
git rev-parse --is-shallow-repository
git describe
```

<!-- snippet: ch14b/describe-shallow/04-unshallow -->
```text
$ git fetch --unshallow
$ git rev-parse --is-shallow-repository
false
$ git describe
v1.0.0-2-g72212ba
```
<!-- /snippet -->

**[ANIMATION]** step: shallow.unshallow

With full history, the same string as on the laptop.

**[ON SCREEN]** Lower third: **GitHub Actions**. The textbook states that `actions/checkout` fetches one commit and no tags by default, and that `fetch-depth: 0` fetches everything. The Actions part of the course returns to this.

**[TERMINAL]** Replay `labs/run ch14b/release-branch`. Version 1.2.0 is tagged; `main` has moved on with a feature, a fix and another feature.

```bash
git log --oneline --decorate
git switch -c release/1.2 v1.2.0
```

<!-- snippet: ch14b/release-branch/01-branch-from-tag -->
```text
$ git log --oneline --decorate
8ed5c59 (HEAD -> main) Add batch endpoint
362b359 Fix max_tokens limit
27d1fb6 Add streaming responses
eb112a5 (tag: v1.2.0) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git switch -c release/1.2 v1.2.0
Switched to a new branch 'release/1.2'
```
<!-- /snippet -->

🟡 CAUTION: `git cherry-pick` makes a new commit on the current branch. The fix was made on `main` first. Copy it with `-x`, which records the source commit in the message.

```bash
git cherry-pick -x main~1
git log -1 --format=%B
git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
```

<!-- snippet: ch14b/release-branch/02-backport -->
```text
$ git cherry-pick -x main~1
[release/1.2 c40960e] Fix max_tokens limit
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format=%B
Fix max_tokens limit

(cherry picked from commit 362b3592d29ea9c07389c0782fd46c24269b6a3f)

$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
```
<!-- /snippet -->

The new commit is `c40960e`, and its message ends with "cherry picked from commit" and the full ID of the original. Now both lines. Predict what `git describe main` prints, given that 1.2.1 has been released. Say it out loud.

```bash
git log --graph --oneline --decorate --all
git describe release/1.2
git describe main
```

<!-- snippet: ch14b/release-branch/03-two-lines -->
```text
$ git log --graph --oneline --decorate --all
* c40960e (HEAD -> release/1.2, tag: v1.2.1) Fix max_tokens limit
| * 8ed5c59 (main) Add batch endpoint
| * 362b359 Fix max_tokens limit
| * 27d1fb6 Add streaming responses
|/  
* eb112a5 (tag: v1.2.0) Add rate limits
* 516c4c3 Add model router
* 37da450 Add README
$ git describe release/1.2
v1.2.1
$ git describe main
v1.2.0-3-g8ed5c59
```
<!-- /snippet -->

**[ANIMATION]** step: rel.three

`main` describes itself from `v1.2.0`, three commits on. `v1.2.1` isn't an ancestor of `main`, and describe only looks backward along history. That's the second question from the opening, answered. Now the incident question: which releases contain the fix?

```bash
git tag --contains main~1
git tag --contains release/1.2
git tag --merged main
git cherry -v release/1.2 main
```

<!-- snippet: ch14b/release-branch/04-what-contains-the-fix -->
```text
$ git tag --contains main~1
$ git tag --contains release/1.2
v1.2.1
$ git tag --merged main
v1.2.0
$ git cherry -v release/1.2 main
+ 27d1fb6a67cdb41e87d5771c3e10310823ee0dcb Add streaming responses
- 362b3592d29ea9c07389c0782fd46c24269b6a3f Fix max_tokens limit
+ 8ed5c59df2f47f80f396b5ba11769efbe1d6491e Add batch endpoint
```
<!-- /snippet -->

**[ANIMATION]** step: rel.three

**[ANIMATION]** say: git_cherry_compares_patches:_362b359_has_an_equivalent,_c40960e

No tag contains the original fix commit `362b359`: the first command prints nothing. The release has the copy. `git cherry` compares patches, not IDs, and its minus line says that the fix on `main` has an equivalent on the release branch. The plus lines are what the release branch doesn't have.

**[ANIMATION]** end

When 1.3.0 is cut from `main`:

<!-- snippet: ch14b/release-branch/05-next-minor -->
```text
$ git switch -q main
$ git tag -a v1.3.0 -m "inference-gateway 1.3.0"
$ git tag --sort=version:refname
v1.2.0
v1.2.1
v1.3.0
$ git describe main
v1.3.0
$ git log --oneline v1.2.1..v1.3.0
8ed5c59 Add batch endpoint
362b359 Fix max_tokens limit
27d1fb6 Add streaming responses
$ git log --oneline --cherry-pick --right-only v1.2.1...v1.3.0
8ed5c59 Add batch endpoint
27d1fb6 Add streaming responses
```
<!-- /snippet -->

**[ANIMATION]** step: rel.minor

`main` now describes itself as `v1.3.0`, and the range from `v1.2.1` to `v1.3.0` lists three commits, including the original of the fix that 1.2.1 already has as a copy.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Computing a version in a shallow CI checkout.** Root cause: describe needs a tagged ancestor and every commit between it and HEAD, and a depth-1 clone has neither.
2. **Fetching only the tag to "fix" the shallow build.** Root cause: the commits between the tag and the tip are still missing, so the tag is not connected to HEAD.
3. **Tagging releases with lightweight tags and wondering why describe ignores them.** Root cause: describe uses annotated tags unless `--tags` is given.
4. **Looking for the fix's commit ID on the release branch.** Root cause: a cherry-pick creates a new commit with a new ID; containment by ID does not see copies.
5. **Publishing a describe string as a semantic version.** Root cause: by the pre-release rule a hyphenated suffix sorts before the release it names.

## PRODUCTION EXAMPLE

Now, out of the lab. A model-serving team runs `1.2.x` for a regulated customer and `1.3.x` for everyone else. The customer's auditor asks: is the token-limit fix in what we run?

The engineer doesn't search the release branch for the fix's commit ID, where it will never be. She runs `git cherry -v release/1.2 main` and reads the minus line for the fix, and she shows the trailer that `-x` wrote on the release-branch commit, which names the original. Then `git tag --contains` on the release-branch commit names the patch release. The answer to the auditor has three parts: the original commit, the backported commit, and the tag that contains the backport.

The same team's release job computes its version with full history and fails when `git describe --exact-match` fails, so an untagged commit can't be published as a release.

## PRACTICE EXERCISE

Your turn. Do Lab 13.3, "Describe and versions", in [`lab-manual/m13-tags-versions.md`](../../lab-manual/m13-tags-versions.md).

Before every `git describe` in the lab, write the exact string you expect, all three parts, or the error. In the shallow part, predict the output after each of the three fetches before you run it.

The challenge is Exercise 13.6, Level 2, draw the graph, "A patch release from a release branch", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q102: "`git describe` prints `v1.0.0-2-gc053f0d` on a laptop and fails in CI. Explain every part of the string and the failure."

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: desc.state-2

**[ANIMATION]** say: The_nearest_annotated_tag,_the_commits_since,_g_and_the_abbreviated_ID

A strong answer takes the string apart in order and says where each part comes from in the graph, including what the single letter means and which kind of tag qualifies. It then states what describe needs in order to produce that string, and from that derives the CI failure as a property of the checkout, not of the tool. It explains why fetching the tag alone doesn't help. It names the layer the default belongs to. And it offers a fix and a guard: what the job should fetch, and which check makes a release job fail loudly instead of publishing a fallback version.

## RECAP

Let's land this. You should now be able to say:

- A describe string is the nearest annotated tag, the number of commits since, and "g" plus the abbreviated ID; it is itself a valid revision.
- Describe needs the tag and the history between the tag and the commit, so it fails in a shallow clone.
- Semantic Versioning gives meaning to MAJOR, MINOR and PATCH, makes a released version immutable, and sorts pre-releases before the release.
- A release branch starts at a tag and receives fixes; each patch release is a tag on it.
- After a backport, "which releases contain this fix" is answered by patch comparison and by the `-x` trailer, not by the commit ID.

## HOMEWORK

Read sections 14B.12 to 14B.14 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md). Do Exercise 13.4, Level 2, "What `git describe` prints", and Exercise 13.8, Level 3, "One name, two refs", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Today you read a version string back into the graph, and you found which releases contain a fix. Before the next video, run `git describe` in the lab, and predict the string first. Next time: linked worktrees, what is shared, and one branch per worktree. Until then, look at the state first and type second. See you in the next one.

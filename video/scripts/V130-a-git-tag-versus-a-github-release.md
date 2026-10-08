# V130: A Git tag versus a GitHub Release

- **Part.** 5: GitHub
- **Module.** 22
- **Planned minutes.** 18
- **Prerequisites.** V080, V082, V115
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), section 15.12
- **Demo scripts.** `labs/ch15/tag-vs-release.sh`, `labs/ch17/lab-22-2-annotated-tag-release.sh`; GitHub-side walkthrough of Lab 22.2

## HOOK

**[ON SCREEN]** Release page: "v0.3.0". Build log: `v0.2.0-1-g…`.

The release page says v0.3.0. The build machine runs `git describe` and prints v0.2.0, dash one, dash a commit ID. Support asks which version customers have. Your CTO asks: which one is the version?

Both are. A release and a tag are different objects made by different programs. The release was created on the platform for a tag that did not exist, so the platform made a tag, at whatever commit was at the tip of the default branch at that second. Nobody chose that commit with `git tag`. And the build's `git describe` does not count that kind of tag. Keep those two strings in mind. You'll print both.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You learned tags in Part 3: lightweight, a bare name for a commit, and annotated, with its own object, tagger and message. They live under `refs/tags/`, and `git describe` reads them. In video 115 you sorted "release" into the column of GitHub objects and "tag" into the column of Git data. This video is the place where the two columns touch, and where a platform action writes Git data that nobody typed.

One section, 15.12. Two replays: `labs/ch15/tag-vs-release.sh`, in which a plain `git tag` on a bare repository stands in for what the platform does, and the replay of Lab 22.2. Then the walkthrough of Lab 22.2, Part B, on a practice repository.

Labels: `git tag -a` adds a tag object and a ref. `git push origin <tag>` publishes it. `gh release create` is a state change on GitHub and, when the tag does not exist, on the repository's refs. The textbook labels it 🔴 DANGEROUS without `--verify-tag` and 🟡 CAUTION with it, and I always show it with `--verify-tag`.

## LEARNING OBJECTIVES

After this video you can:

- Separate the tag, which is Git data, from the Release, which is a GitHub object.
- Explain how creating a release can create a tag on the server, and of which kind.
- Explain why `git describe` and the release page can disagree.
- Cut a release from an annotated tag that was pushed first.
- Say what an immutable release adds, as the section states it.

## CONCEPT

**[ANIMATION]** stores: id=layers boxes=*Git_data:in_every_clone_after_a_fetch|GitHub_objects:in_no_clone rows=1:A:a_tag:_a_ref_that_names_a_commit|1:B:a_release:_points_at_a_tag_name|2:B:a_title,_notes,_uploaded_assets|2:B:flags:_draft,_pre-release,_latest arrows=1:B1>A1:based_on_Git_tags at_1=15 title=Two_objects,_two_programs

**[ANIMATION]** step: 1

In one sentence: a tag is a Git ref that names a commit. A release is a GitHub record that points at a tag name and adds a title, notes, files and flags.

**[ANIMATION]** step: 2

The Git side you know. The GitHub side, from the documentation: "Releases are based on Git tags." A release adds a title, notes, uploaded assets and three flags: draft, pre-release, latest. Managing releases needs Write.

**[ANIMATION]** say: A release leaves no trace in any clone

Inside `.git`: a release leaves no trace in any clone. The tag does, and only after a fetch.

**[ANIMATION]** graph: bf7889c main atag:v0.2.0#db476fe; HEAD=main => bf7889c-89837fa main; bf7889c atag:v0.2.0#db476fe; HEAD=main => 89837fa main tag:v0.3.0; bf7889c atag:v0.2.0#db476fe; HEAD=main dx=300 title=A_release_for_a_tag_that_did_not_exist id=mech

**[ANIMATION]** step: state-2

Now the mechanism of the hook, on one branch. A tag was made on purpose, and afterwards `main` moved on by one commit.

**[ANIMATION]** step: state-3

Creating a release can create the tag. The REST reference describes a field, `target_commitish`, as the value "that determines where the Git tag is created from". It is unused if the tag already exists, and it defaults to the default branch. The GitHub CLI says the same about itself in its help text: "If a matching git tag does not yet exist, one will automatically get created from the latest state of the default branch."

Of which kind is that tag? The textbook is careful here, and so am I. That a tag created by the release API is lightweight is an inference, marked unverified: the CLI help tells you to create annotated tags yourself, and a lab has you check with `git cat-file -t`. In the replay, a lightweight tag stands in for it.

Why would the kind matter? Because `git describe` uses annotated tags only, unless you give `--tags`. Annotated tags are meant for releases, lightweight tags for private labels. A lightweight tag has no tag object, no tagger and no message.

**[ANIMATION]** gates: id=order packet=v0.2.0 gates=git_tag_-a:done:your_clone:a_tag_object_and_a_ref|git_push_origin_<tag>:done:the_server:the_same_two_on_the_server|gh_release_create_--verify-tag:pass:GitHub:aborts_if_the_tag_does_not_exist result=a_release_on_the_commit_you_chose title=The_order_of_work

The prevention has an order. Create and push the annotated tag first. Then create the release with `--verify-tag`, which aborts the release if the tag does not already exist. The CLI's own help gives the procedure: "To create a release from an annotated git tag, first create one locally with git, push the tag to GitHub, then run this command." `--notes-from-tag` takes the release notes from the annotated tag's message.

**[ANIMATION]** end

Generated notes. They list merged pull requests and contributors, and are configured in `.github/release.yml`, where labels and authors can be excluded or grouped. Their quality is the quality of your pull request titles and labels.

**[ANIMATION]** cards: id=immutable question=An_immutable_release,_once_published cards=the_tag_is_locked_to_its_commit|the_tag_cannot_be_deleted:while_the_release_exists|assets_cannot_be_changed|the_tag_name_is_never_reused|a_signed_attestation:gh_release_verify marks=1:lock,2:lock,3:lock,4:lock,5:ok

Immutable releases, generally available since the twenty-eighth of October 2025. Once published: the tag is locked to its commit and cannot be deleted while the release exists. Assets cannot be changed. The tag name can never be reused. And a signed release attestation is generated, checked with `gh release verify`. The documented order is: create a draft, attach the assets, publish.

**[ANIMATION]** end

Two more items the textbook marks unverified, which I repeat as unverified: what happens to a release when its tag is deleted, and whether immutable releases are limited to certain plans, are not stated in the documentation the course read.

The recovery, when the wrong thing has happened: decide which commit is the version. Then either describe with `--tags`, or replace the tag properly. And the root-cause box adds that a new annotated tag under a new name is safer than moving one.

**[ON SCREEN]** The state table of section 15.12.

`git tag -a` then `git push origin v0.2.0`: locally, a tag ref and a tag object. On the remote, both are created. On GitHub, the tag is listed and no release exists. `gh release create v0.2.0 --verify-tag --generate-notes`: nothing changes in Git anywhere, and GitHub gains a release pointing at the existing tag. `gh release create v0.3.0` when no such tag exists: your clone is unchanged until you fetch. The remote gains a tag created from the default branch or from `--target`. GitHub has a release, and a tag you did not make. `gh release delete`: the tag stays, unless `--cleanup-tag` is given, and the release is gone.

**[ANIMATION]** cards: id=quiz question=gh_release_delete,_no_other_option:_what_happens_to_the_tag? cards=A,_it_is_deleted_too|B,_it_stays marks=2:ok

**[ANIMATION]** step: 2

Quick quiz on that last row, from memory now that the table is gone. `gh release delete`, no other option: what happens to the tag? A: deleted too. B: it stays. Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

B. The release is GitHub's record, the tag is Git data, and it stays.

## MENTAL MODEL

**[ANIMATION]** stores: id=casting boxes=the_casting:the_metal|*the_catalogue:the_platform rows=1:A:the_mark_stamped_on_it:_a_tag|1:B:the_catalogue_page:_a_release|2:A:a_mark_stamped_for_you,_at_the_front_of_the_line@bad|3:A:stamp_first,_by_hand@ok|3:B:then_ask_for_the_page@ok arrows=1:B1>A1:describes|2:B1>A2:a_page_for_a_mark_that_does_not_exist at_1=20 title=The_mark_and_the_catalogue_page

**[ANIMATION]** step: 1

The textbook's analogy: a tag is the mark stamped on a casting. A release is the catalogue page for it, with a description and a download. The page can be rewritten without touching the metal.

**[ANIMATION]** step: 2

The analogy breaks in one dangerous place: asking for a page for a mark that does not exist makes the platform stamp the mark for you, on whatever is at the front of the line.

**[ANIMATION]** step: 3

So the discipline is the order of work. Stamp first, by hand, on the casting you chose. Then ask for the page, and tell the catalogue to refuse if it cannot find your stamp.

**[ANIMATION]** end

Try it now, thirty seconds, on paper: write the three commands of a release, in that order. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: order.result

`git tag -a`, then `git push origin` with the tag name, then `gh release create` with `--verify-tag`.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** One repository, two tags, and the platform side.

```text
   Git data (in every clone after a fetch)                         GitHub objects (in no clone)

   refs/tags/v0.2.0 --> tag object db476fe --> commit bf7889c       Release "v0.2.0"
                        tagger, date, message      |                   points at tag name v0.2.0
                        (annotated)                |                   title, notes, assets, flags
                                                   v
   refs/tags/v0.3.0 -------------------------> commit 89837fa       Release "v0.3.0"
                        (lightweight: no tag object,                   points at tag name v0.3.0
                         no tagger, no message)                        created first; the tag was made
                                                                       by the platform at the tip of main

   git describe origin/main          ->  v0.2.0-1-g89837fa    (annotated tags only)
   git describe --tags origin/main   ->  v0.3.0
```

On the left, Git. The first tag goes through a tag object, `db476fe`, which has a tagger, a date and a message, to commit `bf7889c`. The second tag points directly at commit `89837fa`: no object in between.

On the right, the platform. Two release records, each pointing at a tag name. Nothing on the right is in a clone.

At the bottom, the hook as two commands. `git describe` counts from the nearest annotated tag: v0.2.0, one commit later. With `--tags` it sees the lightweight one: v0.3.0.

**[ON SCREEN]** The root-cause box of section 15.12.

```text
Observed behavior : The release page says v0.3.0. "git describe" on the build machine prints v0.2.0-1-g89837fa.
Git state         : refs/tags/v0.3.0 exists and names the commit 89837fa directly. It is a lightweight
                    tag: no tag object, no tagger, no message.
Mechanism         : "git describe" uses annotated tags only, unless --tags is given (Chapter 14B).
Root cause        : The release was created for a tag that did not exist, so the tag was created by
                    the platform at the tip of the default branch, not by a person with "git tag -a".
Why Git does this : Annotated tags are meant for releases, lightweight tags for private labels.
Correct fix       : Decide which commit is the version. Then either describe with --tags, or replace
                    the tag properly: a new annotated tag under a new name is safer than moving one.
Prevention        : Create and push the annotated tag first; create the release with --verify-tag.
                    Protect tags with a tag ruleset; use immutable releases for anything you ship.
```

Read the root-cause line: the release was created for a tag that did not exist, so the platform created the tag at the tip of the default branch.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch15/tag-vs-release
```

**[ANIMATION]** graph: bf7889c main atag:v0.2.0#db476fe; HEAD=main => bf7889c-89837fa main; bf7889c atag:v0.2.0#db476fe; HEAD=main => 89837fa main tag:v0.3.0; bf7889c atag:v0.2.0#db476fe; HEAD=main dx=300 title=prompt-registry:_one_tag_typed,_one_tag_made_by_the_platform id=demo

**[ANIMATION]** step: state-1

You create an annotated tag on the tip of the branch and push it, the way a release is cut on purpose.

```bash
cd you/prompt-registry
git tag -a v0.2.0 -m "prompt-registry 0.2.0: first tagged version"
git push origin v0.2.0
git ls-remote --tags origin
```

**[PAUSE]** One tag was pushed. How many lines will `git ls-remote --tags` print for it?

<!-- snippet: ch15/tag-vs-release/01-annotated -->
```text
$ cd you/prompt-registry
$ git tag -a v0.2.0 -m "prompt-registry 0.2.0: first tagged version"
$ git push origin v0.2.0
To ../../server/prompt-registry.git
 * [new tag]         v0.2.0 -> v0.2.0
$ git ls-remote --tags origin
db476fed4f3e711eb2a4ef4c4fe223c0844878dc	refs/tags/v0.2.0
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/tags/v0.2.0^{}
```
<!-- /snippet -->

Two lines for one tag: the tag object, and with the `^{}` suffix the commit it points at.

**[ANIMATION]** step: state-3

Then Asha merges one more commit. Then someone creates a release v0.3.0 on the platform, without creating a tag first. A plain `git tag` on the bare repository stands in for what the platform does at that point.

```bash
git -C ../../server/prompt-registry.git tag v0.3.0 main
git tag --list
git ls-remote --tags origin
```

<!-- snippet: ch15/tag-vs-release/02-server-side-tag -->
```text
# Asha has merged one more commit. Then a release "v0.3.0" is created on the platform for a tag
# that does not exist. Stand-in for what the platform does: a tag at the tip of the default branch.
$ git -C ../../server/prompt-registry.git tag v0.3.0 main
$ git tag --list
v0.2.0
$ git ls-remote --tags origin
db476fed4f3e711eb2a4ef4c4fe223c0844878dc	refs/tags/v0.2.0
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/tags/v0.2.0^{}
89837fa8e400e276bac7ab81de1460e9df49316a	refs/tags/v0.3.0
```
<!-- /snippet -->

The server has a tag that your clone has never seen: `git tag --list` still shows one. And for the new tag there is one line this time: no tag object, only a ref that names a commit. Predict: after a fetch, how many tags will your clone list? Say it out loud.

**[PAUSE]**

```bash
git fetch origin
git tag --list
```

<!-- snippet: ch15/tag-vs-release/03-fetch -->
```text
$ git fetch origin
From ../../server/prompt-registry
   bf7889c..89837fa  main       -> origin/main
 * [new tag]         v0.3.0     -> v0.3.0
$ git tag --list
v0.2.0
v0.3.0
```
<!-- /snippet -->

Two. The fetch brings the commit and the tag.

```bash
git for-each-ref --format="%(refname:short)  %(objecttype)  tagger=%(taggername)  %(subject)" refs/tags
```

<!-- snippet: ch15/tag-vs-release/04-two-kinds -->
```text
$ git for-each-ref --format="%(refname:short)  %(objecttype)  tagger=%(taggername)  %(subject)" refs/tags
v0.2.0  tag  tagger=Lab User  prompt-registry 0.2.0: first tagged version
v0.3.0  commit  tagger=  Document that versions are immutable
```
<!-- /snippet -->

Two kinds, in one listing. v0.2.0 has object type `tag`, a tagger and its own message. v0.3.0 has object type `commit`, an empty tagger, and the subject shown is the commit's.

```bash
git describe origin/main
git describe --tags origin/main
```

**[PAUSE]** The tip of `main` carries the tag v0.3.0. What does plain `git describe` print?

<!-- snippet: ch15/tag-vs-release/05-describe -->
```text
$ git describe origin/main
v0.2.0-1-g89837fa
$ git describe --tags origin/main
v0.3.0
```
<!-- /snippet -->

`v0.2.0-1-g89837fa`: one commit after the last annotated tag. With `--tags`: `v0.3.0`.

**[ANIMATION]** step: state-3

Both are true statements about the same commit. That's the build log and the release page from the hook.

**[TERMINAL]** The lab replay does it in the right order, on `ticket-router`.

```bash
labs/run ch17/lab-22-2-annotated-tag-release
```

<!-- snippet: ch17/lab-22-2-annotated-tag-release/01-tag -->
```text
$ cd you/ticket-router
$ git log --oneline -2
9a383e5 Add classifier test
f3e7ca9 Add routing config
$ git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"
$ git cat-file -t v0.1.0
tag
$ git cat-file -p v0.1.0
object 9a383e547a1c8840f3c5c7b23bfab6120f366ed0
type commit
tag v0.1.0
tagger Lab User <you@example.com> 1788756180 +0530

ticket-router 0.1.0: keyword classifier
```
<!-- /snippet -->

An annotated tag is an object of its own: type `tag`, and inside it the object it names, the type, the tag name, the tagger and the message.

<!-- snippet: ch17/lab-22-2-annotated-tag-release/03-release -->
```text
# On GitHub the next step is: gh release create v0.1.0 --verify-tag --notes-from-tag
# The release is a GitHub object. The Git data it points at is what you see here:
$ git for-each-ref --format="%(refname) %(objecttype) -> %(*objecttype) %(*objectname:short)" refs/tags
refs/tags/v0.1.0 tag -> commit 9a383e5
```
<!-- /snippet -->

What a release would point at: the tag ref, of type `tag`, peeled to a commit. On GitHub the next step is the release command with `--verify-tag`.

**[ON SCREEN]** GitHub walkthrough, Lab 22.2 Part B, in the normal shell, on the lab's starter repository. The interface changes; the documentation "about releases" and the help text of `gh release create` are the reference. No output is shown.

```bash
git switch main && git pull --ff-only
git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"
git push origin v0.1.0
gh release create v0.1.0 --verify-tag --notes-from-tag --title "ticket-router 0.1.0"
gh release view v0.1.0
gh release list
git ls-remote --tags origin
```

Say what each line creates and where. The tag: an object and a ref in your clone. The push: the same two on the server. According to the documentation the tag is now listed on the repository's tags page, and no release exists yet. `gh release create`: a GitHub object and nothing in Git, because `--verify-tag` found the tag. In the browser, the releases page shows the title, the notes taken from the tag message, and the source archives GitHub attaches. Finally `git ls-remote --tags`: predict the number of lines before you run it.

The lab then has you create a release first, for a tag that does not exist, look at the tag the platform made with `git cat-file -t`, and repair it. Record what you find: it is the observation behind the unverified note.

## COMMON MISTAKES

Five mistakes to watch for.

1. Creating a release in the web interface for a version that has no tag. Root cause: the platform creates the tag, from the default branch unless a target is given, at a commit nobody chose with `git tag`.
2. Deriving a version with `git describe` and wondering why a tag is ignored. Root cause: `git describe` uses annotated tags only, unless `--tags` is given.
3. Deleting a release to "undo" it and assuming the tag is gone. Root cause: `gh release delete` leaves the tag unless `--cleanup-tag` is given.
4. Expecting release notes, assets or the "latest" flag in a clone or a mirror. Root cause: a release is a GitHub object; only the tag is Git data.
5. Moving a published tag to fix a wrong release. Root cause: clones that fetched the old tag keep it; a new annotated tag under a new name is safer.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: demo.state-3

**[ANIMATION]** say: A lightweight tag at the tip of main: git describe still reports the annotated one

Now, out of the lab. A workflow builds a container image for an inference service whenever a tag matching `v*` is pushed, and derives the version string with `git describe`. A product manager creates "v1.9.0" in the web interface on a Friday evening. The tag lands on whatever `main` was at that second, the workflow fires, and the version string inside the artifact is wrong, because the tag is lightweight and `git describe` reports the previous annotated tag plus a count.

**[ANIMATION]** end

The textbook names three controls that close the gap. A tag ruleset that restricts who may create `v*` tags, which is three videos from now. `--verify-tag` in every release script. And immutable releases for anything you ship.

**[ANIMATION]** step: order.result

The team adds a fourth, procedural one, which is this video's lab in one line: the release engineer creates and pushes the annotated tag, and the release is created from it.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Lab 22.2, "A release from an annotated tag", in [`lab-manual/m22-merge-methods-releases.md`](../../lab-manual/m22-merge-methods-releases.md). Before each `git ls-remote --tags`, predict the number of lines and what each names. Before the failure scenario, predict the object type of the tag the platform will create and what `git describe` will print afterwards, with and without `--tags`.

The challenge is Exercise 22.5, "The release that does not contain its fix", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 227 of the CTO question bank:

> "Explain a Git tag versus a GitHub Release. How can a release point at a commit nobody chose, and what prevents it?"

**[PAUSE]**

Answer out loud. A strong answer puts each of the two in its layer and says what travels with a clone. It describes the sequence that makes the platform create a tag, where that tag is placed, and why a build's version string can then disagree with the release page. For prevention it gives the order of operations, the flag, and at least one platform control, and it is honest about what the documentation does not state.

## RECAP

**[ANIMATION]** step: demo.state-3

**[ANIMATION]** say: off

Let's land this. A tag is Git's, a release is GitHub's, and the order of work keeps them in agreement.

You should now be able to say:

- A tag is a ref, lightweight or annotated; a release is a GitHub record that points at a tag name.
- Creating a release for a tag that does not exist makes the platform create the tag, from the default branch unless a target is given.
- `git describe` counts annotated tags only, so it can disagree with the release page.
- The order is: annotated tag, push, then `gh release create --verify-tag`.
- An immutable release locks the tag to its commit, fixes the assets, and adds an attestation.

## HOMEWORK

Read section 15.12 of [Chapter 15](../../textbook/ch15-github.md).

You can now cut a release on the commit you chose. Practise with Lab 22.2. Next: rulesets, layering and bypass. Until then, look at the state first and type second. See you in the next one.

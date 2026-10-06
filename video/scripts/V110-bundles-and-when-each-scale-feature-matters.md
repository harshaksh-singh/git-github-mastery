# V110: Bundles, and when each scale feature matters

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 16
- **Prerequisites.** V079, V109
- **Textbook sections.** [Chapter 26](../../textbook/ch26-performance.md), sections 26.14 and 26.15 (with 26.16 to 26.18 for failures and labels)
- **Demo scripts.** `labs/ch26/bundles.sh`, `labs/ch26/lab-18-3-bundle-round-trip.sh`

## HOOK

**[ON SCREEN]** Two boxes, "office" and "training cluster", with no line between them.

The training cluster is air-gapped. It has no network route to your Git server, and it needs your code every week. Your CTO asks: how do we ship it, and how do we ship only what is new?

The answer is a file. One full bundle to start, then an incremental bundle per week. And the second half of the question hides the risk: an incremental bundle names what the other side must already have. Lose one shipment, and the next one is refused. Keep that lost shipment in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You created and cloned bundles earlier in the course, in the remote operations and recovery chapters. Two things remain. The incremental bundle with its prerequisite, and `--bundle-uri`, which seeds a clone from a bundle and takes only the remainder from the server.

Then we close the scale topic with one table from section 26.15: which feature matters when. Its message is that most repositories need none of what the last four videos showed.

Replays: `labs/ch26/bundles.sh`, and the replay of Lab 18.3 up to its checkpoint. `git bundle create` is 🟢 SAFE: it writes a file. `git bundle verify` changes nothing.

## LEARNING OBJECTIVES

After this video you can:

- Create a full and an incremental bundle and read a bundle's header.
- Explain what a prerequisite is and what happens when one shipment is lost.
- Clone from a bundle and continue from the network.
- Say for a repository of a given size which scale features are worth enabling.

## CONCEPT

In one sentence: a bundle is a file that holds a pack and the refs that go with it, and an incremental bundle is one that names commits the receiver must already have. A pack is one file of many objects, and a ref is a name such as a branch.

Why does it exist? Because a fetch needs a conversation, and some sites can't have one. A bundle is the server's half of a fetch, written to a file.

**[ANIMATION]** graph: 100bb99-aa0428a-6d3aa59 main; 100bb99 tag:schemas/v1.1.0; HEAD=main; range:aa0428a,6d3aa59:schemas/v1.1.0..main; note:100bb99:the_prerequisite title=The_range_schemas/v1.1.0..main id=range at_state_1=15

How do you make an incremental one? From a range: `git bundle create <file> <old>..<new>`. A range is the commits reachable from the new end and not from the old one. Such a bundle contains only the objects that the range adds, and it records `<old>` as a prerequisite. `git bundle verify`, and every fetch from the bundle, refuse a repository that lacks the prerequisite. On screen is today's range: the two commits after `100bb99`.

**[ANIMATION]** stores: boxes=*orbit-update.bundle:a_text_header,_then_a_pack|the_receiving_repository:what_it_must_already_have rows=1:A:#_v2_git_bundle|2:A:-100bb99..._(prerequisite)@hl|2:B:commit_100bb99@ok|3:A:6d3aa59..._refs/heads/main|3:A:b796e9e..._refs/tags/gateway/v1.2.0|4:A:an_empty_line|4:A:the_pack:_only_what_the_range_adds arrows=2:A2>B1:requires title=Inside_an_incremental_bundle say_1=A_signature_line say_2=One_line_per_prerequisite,_starting_with_a_minus_sign say_3=One_line_per_ref say_4=An_empty_line,_then_a_thin_pack id=bundle

**[ANIMATION]** step: 4

Internally, the file is a short text header followed by a pack. A signature line. One line per prerequisite, starting with a minus sign. One line per ref. An empty line. Then the pack. An incremental bundle is thin on purpose, and its deltas, objects stored as differences from other objects, may be based on objects it doesn't contain. That's why the prerequisite is a hard requirement and not a courtesy.

**[ANIMATION]** flow: actors=your_new_clone,a_bundle,*the_server subs=-,for_example_on_a_CDN,- msgs=2>1:the_bulk_of_the_clone|3>1:only_the_remainder:ok title=git_clone_--bundle-uri id=seed

The second feature: `git clone --bundle-uri=<uri>` takes the bulk of a clone from a bundle, for example from a CDN, and only the remainder from the server. Servers can advertise bundle URIs themselves, and clients ignore that unless `transfer.bundleURI` is set. The option needs Git 2.38 or later, and it's incompatible with `--depth`.

**[ANIMATION]** end

When should you not use a bundle? As a backup of everything. A bundle carries no reflogs, hooks or configuration.

**[ANIMATION]** walk: columns=,from_the_chapter's_table rows=symptom:Repository_lacks_these_prerequisite_commits|diagnosis:an_incremental_bundle_arrived_without_its_predecessor|fix:apply_the_missing_bundle,_or_cut_a_new_one_from_what_the_site_has|prevention:number_the_bundles,_and_record_the_basis_in_a_tag marks=1.2:bad,3.2:ok,4.2:ok title=When_one_shipment_is_lost mono=off id=lost

**[ANIMATION]** step: 4

Failure mode and recovery, from the chapter's table. The symptom is `Repository lacks these prerequisite commits`. The diagnosis: an incremental bundle arrived without its predecessor. The fix: apply the missing bundle, or cut a new one from what the site has. The prevention: number the bundles, and record the basis in a tag.

## MENTAL MODEL

**[ANIMATION]** step: bundle.4

**[ANIMATION]** say: Each_later_parcel_begins:_continued_from_page_412

Think of weekly instalments of a serial sent by post. The first parcel is the whole story so far. Each later parcel begins "continued from page 412". If you hold page 412, you can read on. If a parcel was lost, the next one is useless to you until the gap is filled, and it says so on its first page.

**[ANIMATION]** step: range.state-1

**[ANIMATION]** say: A_new_bundle_can_be_cut_from_any_commit_the_receiver_still_has

The model breaks in one respect: the sender doesn't have to resend the lost parcel. Because the sender has the whole history, a new parcel can be cut from any point the receiver still has. The prerequisite is a statement about the receiver's state, not about the sequence of files.

## DIAGRAM

**[DIAGRAM]** Two sites, no network, a file carried across.

```text
   connected site (orbit)                              isolated site (site-b)

   ... --- 100bb99 --- aa0428a --- 6d3aa59  main       ... --- 100bb99   main
              ^                                                   ^
              | prerequisite                                      | must already be here
              |
   orbit-update.bundle                     carried by hand
   +----------------------------------+    ============>   git bundle verify   : okay
   | # v2 git bundle                  |                    git fetch <bundle>  : 100bb99..6d3aa59
   | -100bb99...   (prerequisite)     |
   | 6d3aa59...  refs/heads/main      |    into an empty repository:
   | b796e9e...  refs/tags/gateway/.. |    error: Repository lacks these prerequisite commits
   | (pack: only what the range adds) |
   +----------------------------------+
```

On the left, the connected site. Its `main` has moved two commits past `100bb99`. On the right, the isolated site, which was cloned from the full bundle when `100bb99` was the tip.

The file in the middle: a header and a pack. The line with the minus sign is the prerequisite. Find `100bb99` on both sides. The bundle applies on the right because that commit is there. Carried into an empty repository, the same file is refused.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch26/bundles
```

```bash
git bundle create ../orbit-full.bundle --all
git bundle verify ../orbit-full.bundle | tail -2
git log --oneline schemas/v1.1.0..main
git bundle create ../orbit-update.bundle schemas/v1.1.0..main gateway/v1.2.0
git bundle verify ../orbit-update.bundle
```

The second bundle is made from a range. What will `verify` say that it didn't say about the first? I'll wait.

**[PAUSE]**

<!-- snippet: ch26/bundles/01-full-and-incremental -->
```text
$ git bundle create ../orbit-full.bundle --all
$ git bundle verify ../orbit-full.bundle | tail -2
../orbit-full.bundle is okay
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
# Two more commits and a release tag, then a bundle of only what is new since the last one:
$ git log --oneline schemas/v1.1.0..main
6d3aa59 gateway: retry the upstream twice
aa0428a gateway: lower the upstream timeout to 600 ms
$ git bundle create ../orbit-update.bundle schemas/v1.1.0..main gateway/v1.2.0
$ git bundle verify ../orbit-update.bundle
../orbit-update.bundle is okay
The bundle contains these 2 refs:
6d3aa5958cd87cc93b3d598f9d92f1c1289f1204 refs/heads/main
b796e9ea912be02a0f9a0e2471070693a83a6efa refs/tags/gateway/v1.2.0
The bundle requires this ref:
100bb993157cac87afe81008782cd27cd39f8c9d 
The bundle uses this hash algorithm: sha1
```
<!-- /snippet -->

For the full bundle: "The bundle records a complete history." For the update: two refs, and "The bundle requires this ref", followed by the ID of commit `100bb99`.

```bash
head -n 4 ../orbit-update.bundle
head -n 2 ../orbit-full.bundle | cut -c1-70
```

<!-- snippet: ch26/bundles/02-header -->
```text
# A bundle is a short text header followed by a pack. The header of the incremental bundle:
$ head -n 4 ../orbit-update.bundle
# v2 git bundle
-100bb993157cac87afe81008782cd27cd39f8c9d schemas, gateway, ingest: add the tenant field in one change
6d3aa5958cd87cc93b3d598f9d92f1c1289f1204 refs/heads/main
b796e9ea912be02a0f9a0e2471070693a83a6efa refs/tags/gateway/v1.2.0
$ head -n 2 ../orbit-full.bundle | cut -c1-70
# v2 git bundle
88222b7043b92ba564af0aefc4acd25af9ef15e2 refs/heads/feature/rerank-cac
```
<!-- /snippet -->

The header as text. The signature line, `# v2 git bundle`. The prerequisite line, starting with a minus sign. Then one line per ref. The full bundle has no minus line.

```bash
cd ..
git clone -q orbit-full.bundle site-b
git -C site-b bundle verify --quiet ../orbit-update.bundle
git -C site-b fetch ../orbit-update.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'
git -C site-b merge --ff-only origin/main
git init -q empty
git -C empty bundle verify ../orbit-update.bundle
git clone orbit-update.bundle from-update
```

A quick quiz. `site-b` was cloned from the full bundle. `empty` is a new repository. Which of them accepts the update, and what exactly does the other one print? Your answer?

**[PAUSE]**

<!-- snippet: ch26/bundles/03-prerequisite -->
```text
$ cd ..
# A repository that was cloned from the full bundle has the prerequisite commit:
$ git clone -q orbit-full.bundle site-b
$ git -C site-b bundle verify --quiet ../orbit-update.bundle
../orbit-update.bundle is okay
[exit status: 0]
$ git -C site-b fetch ../orbit-update.bundle 'refs/heads/*:refs/remotes/origin/*' 'refs/tags/*:refs/tags/*'
From ../orbit-update.bundle
   100bb99..6d3aa59  main           -> origin/main
 * [new tag]         gateway/v1.2.0 -> gateway/v1.2.0
$ git -C site-b merge --ff-only origin/main
Updating 100bb99..6d3aa59
Fast-forward
 services/gateway/config.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
# An empty repository does not:
$ git init -q empty
$ git -C empty bundle verify ../orbit-update.bundle
error: Repository lacks these prerequisite commits:
error: 100bb993157cac87afe81008782cd27cd39f8c9d 
[exit status: 1]
$ git clone orbit-update.bundle from-update
Cloning into 'from-update'...
error: Repository lacks these prerequisite commits:
error: 100bb993157cac87afe81008782cd27cd39f8c9d 
fatal: remote transport reported error
[exit status: 128]
```
<!-- /snippet -->

The site that has `100bb99` verifies and fetches the update, and `main` fast-forwards. The empty repository is refused twice, by `verify` and by `clone`, each time with the name of the missing commit. That's the hook's lost shipment.

**[ANIMATION]** graph: 100bb99 main origin/main; HEAD=main => 100bb99-aa0428a-6d3aa59 origin/main; 100bb99 main; HEAD=main => 6d3aa59 main origin/main; HEAD=main title=site-b_applies_the_update id=siteb

On the graph of `site-b`, the fetch moves `origin/main` two commits on. Then the fast-forward moves `main` up to `6d3aa59`.

**[ANIMATION]** end

```bash
GIT_TRACE_PACKET="$PWD/seeded.trace" git clone -q --bundle-uri="$PWD/orbit-full.bundle" "file://$PWD/server/orbit.git" seeded
sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^have'
sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^want'
```

In the last video a plain clone sent eight wants and no haves. What does a clone seeded from a bundle send? Make your prediction.

**[PAUSE]**

<!-- snippet: ch26/bundles/04-bundle-uri -->
```text
# A clone that takes the bulk from a bundle and only the rest from the server:
$ GIT_TRACE_PACKET="$PWD/seeded.trace" git clone -q --bundle-uri="$PWD/orbit-full.bundle" "file://$PWD/server/orbit.git" seeded
$ git -C seeded for-each-ref --format='%(refname)' | sed 's,^\(refs/[a-z]*\)/.*,\1,' | sort | uniq -c
   7 refs/bundles
   1 refs/heads
   3 refs/remotes
   6 refs/tags
# The request to the server offers what the bundle brought:
$ sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^have'
5
$ sed -n 's/.*packet: *clone> //p' seeded.trace | grep -c '^want'
3
$ git -C seeded log --oneline -3
6d3aa59 gateway: retry the upstream twice
aa0428a gateway: lower the upstream timeout to 600 ms
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

Five `have` lines and three `want` lines. The seeded clone first unpacked the bundle, kept its refs in a namespace of their own, and then told the server what it had. One detail the textbook records: on this machine the namespace is `refs/bundles/`, while the manual of `git clone` writes `refs/bundle/`.

**[TERMINAL]** Lab 18.3, up to the checkpoint.

```bash
labs/run ch26/lab-18-3-bundle-round-trip
```

<!-- snippet: ch26/lab-18-3-bundle-round-trip/01-full-bundle -->
```text
$ mkdir transfer
$ cd orbit
$ git bundle create ../transfer/orbit-full.bundle --all
$ git bundle verify ../transfer/orbit-full.bundle | tail -2
../transfer/orbit-full.bundle is okay
The bundle records a complete history.
The bundle uses this hash algorithm: sha1
# Remember what the other site now has (the manual of git bundle uses a tag for this):
$ git tag lastbundle/site-b main
$ cd ..
```
<!-- /snippet -->

The lab adds the bookkeeping. After the full bundle is cut, a tag, `lastbundle/site-b`, records what the other site now has. The manual of `git bundle` uses a tag for this.

<!-- snippet: ch26/lab-18-3-bundle-round-trip/03-update-out -->
```text
# Work continues at the connected site:
$ cd orbit
$ printf 'timeout_ms: 600\nupstream: ranker\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 600 ms'
$ git tag -a gateway/v1.2.0 -m 'gateway 1.2.0'
$ git bundle create ../transfer/orbit-update-1.bundle lastbundle/site-b..main gateway/v1.2.0
$ git bundle verify ../transfer/orbit-update-1.bundle
../transfer/orbit-update-1.bundle is okay
The bundle contains these 2 refs:
65a5f46a8d03c9dc3874674e86cc214b44e24535 refs/heads/main
7a87196129206e084b78ca7141e54ac1cbd851a6 refs/tags/gateway/v1.2.0
The bundle requires this ref:
100bb993157cac87afe81008782cd27cd39f8c9d 
The bundle uses this hash algorithm: sha1
$ git tag -f lastbundle/site-b main
Updated tag 'lastbundle/site-b' (was 100bb99)
$ cd ..
```
<!-- /snippet -->

The update is cut from `lastbundle/site-b..main`, and then the tag is moved forward. Moving a tag with `-f` is a deliberate exception here: this tag is a private bookmark, not a release.

<!-- snippet: ch26/lab-18-3-bundle-round-trip/05-way-back -->
```text
# Work at the isolated site, sent back the same way:
$ printf 'top_k: 20\nmodel: overlap-v1\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'
$ git bundle create ../transfer/site-b-1.bundle origin/main..main
$ git bundle list-heads ../transfer/site-b-1.bundle
abcb4dd332b01640cf92ca83ed3638e74e0ca1d4 refs/heads/main
$ cd ../orbit
$ git fetch ../transfer/site-b-1.bundle main:refs/remotes/site-b/main
From ../transfer/site-b-1.bundle
 * [new branch]      main       -> site-b/main
$ git merge --ff-only site-b/main
Updating 65a5f46..abcb4dd
Fast-forward
 services/ranker/config.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline -3
abcb4dd ranker: return the top 20
65a5f46 gateway: lower the upstream timeout to 600 ms
100bb99 schemas, gateway, ingest: add the tenant field in one change
```
<!-- /snippet -->

And work travels back the same way: the isolated site bundles `origin/main..main`, and the connected site fetches it into a remote-tracking ref and fast-forwards. The lab's failure scenario loses one update. The recovery is yours.

**[ON SCREEN]** The table of section 26.15: feature, matters when.

Now the closing table for the whole scale topic. Automatic maintenance: always. Leave it on. Scheduled maintenance with prefetch: large repositories on developer machines. The commit-graph with changed-path filters: long history and path-limited queries. Geometric repack, multi-pack-index and bitmaps: servers and very large clones. The file-system monitor and the untracked cache: hundreds of thousands of tracked files. Sparse-checkout and the sparse index: a wide tree of which each person needs little. That's the next video. Partial clone: much blob content in history. Shallow clone: throwaway builds of one snapshot. And checking what the pack contains: a repository much larger than its content explains.

The figures the textbook cites for these rows are each reporter's own. One deserves a sentence.

**[ANIMATION]** bars: bars=before:87|after_the_repack:20 unit=GB title=Dropbox's_monorepo,_as_Dropbox_reported_it_in_2026 id=dropbox at_2=20

Dropbox reported in 2026 that its monorepo shrank from 87 GB to 20 GB through repacking, not through deleting history. The cause was the heuristic by which Git chooses delta candidates, which paired translation files of different languages because of the directory layout. The fix was a repack on the server with a larger window and depth. You learned in the packfiles video that a delta is "between two objects chosen for similarity". Here the choice went wrong at scale.

## COMMON MISTAKES

Five mistakes to watch for.

1. Sending an incremental bundle to a site that missed the previous one. Root cause: the bundle is thin and records a prerequisite commit that the receiver must already have.
2. Cutting each update "since last week" from memory. Root cause: the basis must be what the other site actually has; record it in a tag.
3. Treating a bundle as a full backup. Root cause: a bundle carries no reflogs, hooks or configuration.
4. Tuning a small repository with every scale feature. Root cause: each feature is configuration the next person must understand; automatic maintenance is enough until a measured counter is large.
5. Combining `--bundle-uri` with `--depth`. Root cause: the two options are incompatible; not every combination of transfer options works.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: range.state-1

**[ANIMATION]** say: A_tag_records_the_last_shipment:_the_next_bundle_is_cut_from_it

Now, out of the lab. An ML team trains on an air-gapped cluster. Every Friday a release engineer cuts `orbit-update-<n>.bundle` from the tag that records the last shipment to `main`, moves the tag, and hands the numbered file to the operator of the cluster. On the cluster, the operator runs `git bundle verify` before fetching.

**[ANIMATION]** end

Try it now, on paper, thirty seconds. One week a file isn't delivered, and the next one arrives. Write down what `git bundle verify` prints, and one way out. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: lost.4

One week a file isn't delivered. The following Friday, `verify` prints `Repository lacks these prerequisite commits` with one commit ID. Nothing is damaged on either side. The engineer has two options: deliver the missing bundle first, or cut a new bundle from the last commit the cluster reports having. The team's prevention is already in place: numbered bundles, and the basis recorded in a tag.

## PRACTICE EXERCISE

Your turn. Do Lab 18.3, "A bundle round trip", in [`lab-manual/m18-transfer-scale.md`](../../lab-manual/m18-transfer-scale.md). Before each `git bundle verify`, predict whether it will say "complete history" or name a required commit, and which commit. Before the failure scenario, predict the exact refusal.

The challenge is Exercise 18.9, "The clone that believes it is up to date", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md).

## INTERVIEW QUESTION

Question 450 of the CTO question bank:

> "How do you ship weekly updates to a site with no network route to the server? What goes wrong if one shipment is lost?"

A strong answer describes the first shipment and the weekly one separately, and says how the sender knows what the receiver has. For the lost shipment it gives the symptom in Git's words, explains why Git refuses, and offers both ways out. It mentions what a bundle doesn't carry.

## RECAP

**[ANIMATION]** step: siteb.state-3

Let's land this. A file carries history across a gap, if the other side holds the commit it starts from.

You should now be able to say:

- A bundle is a header of refs and prerequisites followed by a pack.
- An incremental bundle is cut from a range and applies only where its prerequisite commit exists.
- `--bundle-uri` seeds a clone from a bundle; the clone then offers what the bundle brought as haves.
- Record what the other site has in a tag, and number the bundles.
- Measure the dimension that is large before choosing a scale feature; most repositories need only automatic maintenance.

## HOMEWORK

Read sections 26.14 to 26.18 of [Chapter 26](../../textbook/ch26-performance.md) and do the Practice section 26.20.

Today you shipped history without a network, and you closed the scale topic. Do the lab before the next video: monorepo versus polyrepo, and sparse-checkout in cone mode. Until then, look at the state first and type second. See you in the next one.

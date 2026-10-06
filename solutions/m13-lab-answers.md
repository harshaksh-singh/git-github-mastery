# Module 13 lab answers: Tags, versions, and release mechanics in Git

Answers to the Questions in [lab-manual/m13-tags-versions.md](../lab-manual/m13-tags-versions.md). Read them after you have written your own. The IDs quoted here are the ones printed by the deterministic replay scripts; where your own run produced other IDs, the reasoning is the same.

## Lab 13.1: Three kinds of tag

1. **Two refs and one object.** `refs/tags/staging-ok` and `refs/tags/v1.0.0` are the refs. The only new object is the tag object that `git tag -a` wrote (`b696248` in the replay). The lightweight tag is a ref that holds the ID of a commit that already existed.

2. **It printed the ID of the tag object**, `b696248…`, because the ref of an annotated tag points at the tag object, and the tag object points at the commit. `git rev-parse 'v1.0.0^{commit}'` peels it to the commit `eb112a5`, and `git show-ref --tags --dereference` prints the peeled value on the line that ends in `^{}`. (`git cat-file -p v1.0.0` shows the same ID in the `object` line.)

3. **The signed tag's text ends with a signature block**, `-----BEGIN SSH SIGNATURE-----` to `-----END SSH SIGNATURE-----`, appended after the message; everything else has the same form. The signature covers the tag object's content before the block: the `object`, `type`, `tag` and `tagger` lines and the message. Before Git would report "Good", it needed a statement of trust from you: the file named by `gpg.ssh.allowedSignersFile`, containing a principal and the public key. Without the file the result was an error, not a failed check.

4. **Because the tag had never left your repository.** The condition is: no other repository can have fetched it, which is certain only if it was never pushed and nobody reads your repository directly. Then `git tag -f` changes a private label. If the tag had been pushed, the old tag would have to stay where it was, and the corrected release would get a new name (`v1.1.1`), as the "On Re-tagging" section of the manual prescribes and as Lab 13.2 plays out.

5. **It is the tag object that `v1.1.0` pointed at before `git tag -f`** (`e9a5be7` in the replay). Replacing the tag rewrote the ref; the old object stayed in the object database with nothing referring to it. `git reflog` does not know it because Git keeps no reflog for tags by default: `core.logAllRefUpdates=true` covers branches, remote-tracking branches, notes and HEAD. You cannot count on the object for long: once it is older than the pruning grace period (two weeks by default, `gc.pruneExpire`) and maintenance runs, it is deleted. The only durable record was the `(was e9a5be7)` in the command's output.

## Lab 13.2: A moved tag between two clones

1. Server: **moved** (your forced push replaced the ref). Yours: **moved** (`git tag -f`). Asha's: **original** (her fetch did not touch a tag she already had). The `ci` clone: **moved** (it copied the server's refs as they were at that moment). Three repositories agreed on the wrong value and one held the right one.

2. **A fetch creates tags that are missing and does not update a tag that exists**, unless you force it; `git fetch --tags` says "would clobber existing tag". It is a protection because a tag name is a promise about content that people and machines rely on: if any fetch could silently repoint `v1.2.0`, whoever controls the server (or compromises it) could change what "version 1.2.0" means in every clone, with no trace. The manual: Git "does not (and it should not) change tags behind users back".

3. **Because the evidence is gone and the lie is now consistent.** While Asha's clone disagreed with the server, a comparison exposed the incident and her ref still named the true 1.2.0. After the forced fetch every clone names code that was never released as 1.2.0, any build "of v1.2.0" silently differs from what was shipped, and no ref anywhere leads back to the original tag object. Consistency is not correctness.

4. **Other places:** your own terminal, where `git tag -f` printed `Updated tag 'v1.2.0' (was 5b231b5)` and `git push --force` printed `+ 5b231b5...`; the output of `git ls-remote --tags origin` from step 1; any CI log, release note, deployment record or package metadata that recorded the tag object or, more usefully, the commit `d20ef7a`, from which an equivalent tag can be recreated if it comes to that. **`git fsck` finds nothing** in a clone that never had the object (the `ci` clone, made after the move), or after the unreachable object has been pruned.

5. **A server rule that refuses to update or delete an existing release tag**: on a plain Git server an `update` or `pre-receive` hook, as in the chapter; on GitHub a tag ruleset. **`receive.denyNonFastForwards` would not have been enough.** The chapter's `moved-tag` demo sets it, together with `receive.denyDeletes`, and the forced tag update and the tag deletion are both accepted; in Git 2.55.0 the code applies both settings only to refs under `refs/heads/`.

## Lab 13.3: Describe and versions

1. `v1.2.0-3-gb520c09`: **`v1.2.0`** is the nearest annotated tag in the history of HEAD; **`3`** is the number of commits that HEAD has and the tag does not; **`gb520c09`** is the letter `g` followed by the abbreviated ID of HEAD. The middle number is the number of lines printed by `git log --oneline "$(git describe --abbrev=0)..HEAD"`.

2. **By default `git describe` considers annotated tags only.** The manual's reasoning: annotated tags are meant for releases, lightweight tags for private or temporary labels, so a version string should not depend on somebody's local marker. `on-staging` is exactly such a marker. `--tags` lifts the restriction, and then the nearest tag of either kind wins.

3. **`v1.2.1` is not an ancestor of `main`.** The tag is on the cherry-picked copy on `release/1.2`; `main` contains the original fix commit, which is a different commit. `git describe` walks parent links backward from the commit it is asked about, and from `main` that walk reaches `v1.2.0` and never `v1.2.1`. It is not a defect: `main` is not "1.2.1 plus something", it is the line that will become 1.3.0. If the team wants `main` to describe itself relative to the newest release, it tags on `main` (as step 5 does with 1.3.0) or merges the release branch back.

4. **`-` means: this commit of `main` has an equivalent on `release/1.2`**, a commit there that introduces the same change. `git cherry` compares patch IDs, which are computed from the diff, not commit IDs. `--contains` asks about reachability of one specific commit object, and the fix exists on the release branch as a *different* object (the cherry-picked copy), so `git tag --contains main~1` cannot list `v1.2.1`. The trailer written by `-x`, "(cherry picked from commit …)", is the human-readable link between the two.

5. **Because `git clone --depth` implies `--single-branch`.** The build clone fetched only `main`; `git fetch --unshallow` completed the history of that one branch and brought the tags that point into it. `v1.2.1` points at a commit that is only on `release/1.2`, which this clone does not track (`git branch -r` shows only `origin/main`). To get it: `git fetch origin tag v1.2.1`, or add the branch with `git remote set-branches --add origin release/1.2` and fetch, or clone with `--no-single-branch` in the first place.

6. **No.** In Semantic Versioning 2.0.0, a hyphen after the patch number starts a pre-release identifier, and a pre-release version has lower precedence than the version itself. Read as SemVer, `1.3.0-1-g3196266` is a pre-release *of* 1.3.0 and sorts before it, while the build it names comes after 1.3.0. (The leading `v` is not part of a semantic version either.) Tools that publish packages from `git describe` output therefore translate it, typically into the next version plus a development or build suffix.

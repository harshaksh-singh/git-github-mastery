# V133: Tag rulesets, push rulesets, organization-level rulesets, classic branch protection, and plan gates

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 20
- **Prerequisites.** V081, V132
- **Textbook sections.** [Chapter 18](../../textbook/ch18-branch-protection.md), sections 18.12 to 18.15
- **Demo scripts.** `labs/ch18/ref-updates.sh` (snippets `the-rules`, `tags`, `disabled-again`), `labs/ch18/fnmatch-targets.sh` (snippet `tags`); GitHub-side walkthrough following Lab 23.1 for where rulesets are managed

## HOOK

**[ON SCREEN]** "`main` is protected. How did a force push get through?" — second answer.

Two videos ago, the answer to "how did a force push get through" was a ruleset that had been left disabled. A force push, remember, replaces a branch on the server and can remove commits from it. Here is the other classic answer, and it is the one that fits most older repositories.

`main` was protected by a classic branch protection rule, created years ago. The person who force-pushed was a repository administrator. And under a classic rule, administrators are not bound by default.

**[ANIMATION]** gates: id=hook packet=git_push_--force gates=the_rule_is_active:pass:-:yes|it_targets_main:pass:-:yes|it_holds_the_restriction:pass:-:yes|it_binds_the_pusher:bypass:-:administrators_are_not_bound_by_default result=the_force_push_goes_through title=A_classic_rule,_and_an_administrator

The rule was active. It targeted the right branch. It contained the right restriction. It did not apply to the person who pushed, and nobody on the team knew that, because only administrators can even see a classic rule.

Your CTO's follow-up is the right one: what else do we have that only looks protected? This video goes through the remaining pieces: tags, pushes, organization-wide rules, the classic mechanism, and what your plan lets you use at all. Keep the CTO's question. We answer it door by door.

**[ANIMATION]** end

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the third video on rules. It covers sections 18.12 to 18.15. A ruleset, as a reminder, is a named list of rules with a target, an enforcement status and a bypass list.

Tag rulesets: rules for refs under `refs/tags/`, so that a release tag cannot move. Push rulesets: rules on the content of a push. Organization-level rulesets: one ruleset for many repositories. Classic branch protection: the older mechanism, still supported and still evaluated alongside rulesets. And plan gates: what you can practise.

Be clear about what is demonstrated and what is taught from the documentation. The tag rules are shown on the local hook model, `labs/ch18/ref-updates.sh`, and a tag ruleset can be created on your practice repository. Push rulesets and organization rulesets cannot be practised in a public repository on a Free organization. They are taught from the documentation, as section 18.15 says.

One command in the replay is 🔴 DANGEROUS: `git push --force` of a tag. It is aimed at the sandbox server, to be refused.

## LEARNING OBJECTIVES

After this video you can:

- Protect release tags with a tag ruleset and test a target pattern before relying on it.
- Say what a push ruleset restricts.
- Say what organization-level rulesets add.
- Name the differences between classic branch protection and rulesets that matter during an incident.
- Say what cannot be practised on a Free plan and how to learn it anyway.

## CONCEPT

**[ANIMATION]** graph: A-B main; A v1.0.0; HEAD=main => B main v1.0.0; HEAD=main title=A_published_tag_that_moves id=tagmove

**[ANIMATION]** step: state-2

Tag rulesets. Why: a release tag that moves is a supply-chain problem. A tag is a name for one commit, and it is not expected to move. Whoever fetched the old tag has one commit under that name. Whoever fetches tomorrow gets another. And a build that resolves the tag by name ships whichever it gets. You met this in the tags videos.

**[ANIMATION]** walk: id=tagrules columns=ref_update_on_a_v*_tag,old_ID,new_ID,the_tag_ruleset_says rows=move:non-zero:non-zero:restrict_updates,_block_force_pushes|delete:non-zero:all_zeros:restrict_deletions|create:all_zeros:non-zero:open,_a_release_can_be_tagged marks=1.4:bad,2.4:bad,3.4:ok mono=off at_1=18 at_2=30 at_3=55 title=A_tag_push_is_a_ref_update

**[ANIMATION]** step: 3

What: on GitHub, a tag ruleset targeting `v*` with three rules: restrict updates, restrict deletions and block force pushes. Creation stays open, so a release can still be tagged. If only the release automation may tag, add restrict creations with a bypass entry for that automation.

**[ANIMATION]** say: A moved tag is an update where both IDs are non-zero

How it works is the mechanism from two videos ago, applied to another namespace: a tag push is a ref update with an old ID, a new ID and a ref name. A moved tag is an update where both IDs are non-zero.

**[ANIMATION]** end

An outdated-advice note: "Tag protection rules" under the repository settings were retired on the thirtieth of August 2024 and migrated to tag rulesets. And do not confuse either with the immutable release from video 130, a second, different mechanism, which locks the tag of a published release.

**[ANIMATION]** step: tagmove.state-2

The target pattern needs the same care as for branches. `v*` matches every tag that begins with a `v`, including ones that are not versions.

Try it now, thirty seconds, on paper: write three tag names that `v*` matches, and make one of them something that is not a version. I'll wait.

**[PAUSE]**

Here are mine: `v1.0.0`, `v2`, and `version-notes`. Keep the third one in mind for the diagram.

**[ANIMATION]** end

Push rulesets. In the documentation's words: "With push rulesets, you can block pushes to a private or internal repository and that repository's entire fork network based on file extensions, file path lengths, file and folder paths, and file sizes. Push rules do not require any branch targeting because they apply to every push to the repository."

**[ANIMATION]** cards: id=pushrules question=A_push_ruleset_looks_at_content,_not_at_refs cards=restrict_file_paths:fnmatch_patterns,_at_most_200_entries|restrict_file_path_length|restrict_file_extensions:at_most_200_entries|restrict_file_size:megabytes,_not_for_Git_Large_File_Storage

**[ANIMATION]** step: 4

Four push rules. Restrict file paths: fnmatch patterns, at most 200 entries of up to 200 characters. Restrict file path length. Restrict file extensions: at most 200 entries. Restrict file size: a limit in megabytes, which does not apply to Git Large File Storage. Also documented: at most 1,000 ref updates per push, and the rules apply to the REST endpoints that create blobs, trees and file contents as well. "Allowed exceptions" for paths and sizes are a preview since the twenty-fifth of August 2026. Do not depend on a preview.

**[ANIMATION]** say: Content, not refs. And forks inherit push rulesets

Two things make push rulesets different from branch rulesets. They look at content, not at refs. And forks inherit them: you heard in the layering section that forks do not inherit branch or tag rulesets and do inherit push rulesets from their root repository.

**[ANIMATION]** say: Plan gate: the Team plan and a private or internal repository

The plan gate: push rulesets need the Team plan and a private or internal repository.

**[ANIMATION]** layers: id=levels layers=enterprise_ruleset:one_more_layer_on_Enterprise_Cloud|organization_ruleset:targets_many_repositories+only_organization_owners_edit_it|repository_ruleset:administrators_may_add_stricter_rules+they_cannot_weaken_the_organization's steps=2,3,1 title=One_ruleset_for_many_repositories

**[ANIMATION]** step: 2

Organization-level rulesets. In one sentence: an organization ruleset is one ruleset that targets many repositories, selected by name pattern, by custom property, or by a filter.

**[ANIMATION]** step: 1

They are available on Team and Enterprise plans since the sixteenth of June 2025. Repositories are targeted as all repositories, only selected repositories, repositories matching a name, or, since the twenty-fourth of June 2025 and by default, repositories matching a filter. Only organization owners can edit them. Repository administrators can add stricter repository rulesets and cannot weaken the organization's. Enterprise-level rulesets add one more layer on Enterprise Cloud.

**[ANIMATION]** end

A caveat the textbook marks unverified: one sentence of GitHub's "About rulesets" still says organization rulesets need the Enterprise plan, while the June 2025 changelog and the organization article say Team. The course records this as a conflict inside GitHub's documentation and prefers the later sources.

Classic branch protection. In one sentence: a classic branch protection rule is the older mechanism: one rule per branch-name pattern, visible to administrators, with its own bypass behaviour, still supported and still evaluated alongside rulesets.

The version note: rulesets are the recommended mechanism since the seventh of July 2026, and since the eleventh of August 2026 a "Convert to ruleset" control migrates one classic rule at a time. No end date for classic rules has been announced. When you inherit a repository, look for classic rules first.

**[ON SCREEN]** The comparison table of section 18.14.

The differences. How many apply to one branch: under classic protection, "only a single branch protection rule can apply at a time". Rulesets are all aggregated. Who can see a classic rule: people with admin access, whereas "anyone with read access to a repository can view its active rulesets". Switching off: you delete the classic rule, and you change the enforcement status of a ruleset. Administrators: under a classic rule, not bound by default, unless "Do not allow bypassing the above settings" is selected. Under a ruleset, bound, unless on the bypass list. Scope: branches of one repository for a classic rule, against branches, tags and pushes at repository, organization and enterprise level. Signed commits when a branch is created: not verified by a classic rule unless matching-branch creation is restricted. And the rejection message Git shows for a classic rule begins `remote: error: GH006: Protected branch update failed`. For rulesets the message is not documented on the pages the course read.

The administrators row is the hook. And one fact for the investigation afterwards: under classic rules the audit log records an administrator's override.

Conversion. The tool converts one classic rule at a time, and the new ruleset is Active at once.

Quick quiz. You convert a classic rule and keep the old one. What must a change satisfy now? A: the new ruleset only. B: the classic rule only. C: both. Your answer?

**[PAUSE]**

**[ANIMATION]** layers: id=both probe=a_change_to_the_branch layers=the_classic_rule:kept|the_converted_ruleset:Active_at_once result=both rule=changes_must_satisfy title=Convert_and_keep

C. If you keep the classic rule, the documentation says, "an Active ruleset is enforced alongside it, so changes must satisfy both". The conversion covers every protection type except "Require conversation resolution before merging". One more caveat marked unverified: how the classic "Lock branch" setting maps onto ruleset rules is not spelled out.

**[ANIMATION]** end

Plan gates. These are the facts most likely to have changed by the time you watch this. Each was read on the first of October 2026.

**[ON SCREEN]** The table of section 18.15.

Repository rulesets and classic branch protection: public repositories on GitHub Free and Free for organizations, and public and private on paid plans. Organization-level rulesets: Team and Enterprise. Enterprise-level rulesets, the Evaluate status, metadata restrictions and ruleset history: the Enterprise Cloud documentation only. Push rulesets: Team plan, private or internal repositories. Merge queue: public repositories owned by an organization, and private ones on Enterprise Cloud. Required reviewers by team: organization-owned repositories. Rule Insights: Team and Enterprise Cloud. Auto-merge: public repositories on Free, and public and private on paid plans.

For you this means one thing: a public repository in a free practice organization. There you can create branch and tag rulesets, bypass lists, required reviews, required checks and code owner review. A private repository on a free plan accepts none of it, which is why the labs are public.

## MENTAL MODEL

**[ANIMATION]** stores: id=doors boxes=the_branch_door:refs/heads|the_tag_door:refs/tags|the_loading_dock:the_content_of_pushes rows=1:A:a_new_lock:_the_ruleset,_with_a_public_list_of_master_keys@ok|1:A:an_old_lock:_the_classic_rule,_keys_with_every_administrator@bad|2:B:maybe_no_lock_at_all@bad|2:C:locked_only_on_a_certain_plan|3:A:on_this_door_the_two_locks_combine:_satisfy_both@hl at_1=30 title=Locks_on_different_doors

**[ANIMATION]** step: 1

Think of the protection of a repository as locks on different doors, fitted in different years by different people. The branch door has a new lock, the ruleset, with a public list of who has a master key. It may also still have an old lock, the classic rule, whose master keys were handed to every administrator by default, and which only administrators can see.

**[ANIMATION]** step: 2

The tag door may have no lock at all. And the loading dock, the content of pushes, is locked only in buildings on a certain plan.

"The repository is protected" is therefore not a statement you can check. "This ref, against this kind of update, by this actor" is.

**[ANIMATION]** step: 3

The model breaks where rulesets are better than locks: two locks on one door do not combine into a stricter lock, but rulesets and a classic rule on the same branch do. Changes must satisfy both.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** A pattern-matching table. Target patterns down the side, ref names across; "match" where the pattern covers the name, a dash where it does not.

```text
  tag targets          v1.0.0     v2        version-notes    release/v1
  v*                   match      match     match            -
  v[0-9]*              match      (n/a)     -                (n/a)

  branch targets       release/1.0   release/1.0/hotfix   feature-x   feature/x   main
  release/*            match         -                    (n/a)       (n/a)       (n/a)
  *feature*            (n/a)         (n/a)                match       -           (n/a)
  **/*                 (n/a)         (n/a)                (n/a)       match       match

  (n/a): not run in the course transcripts
  rule: * does not cross a slash
```

Read the first row. `v*` matches `v1.0.0` and `v2`, as intended. It also matches `version-notes`, a tag that is not a release: under your tag ruleset nobody could move or delete it. And it does not match `release/v1`, because the star does not cross the slash.

The second row, `v[0-9]*`, requires a digit after the `v`: `v1.0.0` matches and `version-notes` does not.

The lower block repeats what you saw two videos ago for branches. The cells marked with the letters n and a were not run in the course transcripts, so I do not fill them in from memory. That is the habit to copy: test a pattern, do not reason about it.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch18/ref-updates
```

<!-- snippet: ch18/ref-updates/01-the-rules -->
```text
$ cat rules/pre-receive
#!/bin/sh
# pre-receive: the server runs this before any ref moves.
# Standard input has one line per proposed ref update: <old id> <new id> <ref name>
zero=0000000000000000000000000000000000000000
status=0
while read old new ref; do
  case "$ref" in
    refs/heads/main)                      # target of the branch rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1; continue
      fi
      [ "$old" = "$zero" ] && continue    # creation: nothing to compare with
      if ! git merge-base --is-ancestor "$old" "$new"; then
        echo "rule 'block force pushes': the update would remove commits from $ref"; status=1
      fi
      if [ -n "$(git rev-list --merges "$old..$new")" ]; then
        echo "rule 'require linear history': the update adds a merge commit to $ref"; status=1
      fi ;;
    refs/tags/v*)                         # target of the tag rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1
      elif [ "$old" != "$zero" ]; then
        echo "rule 'restrict updates': $ref already exists and may not move"; status=1
      fi ;;
  esac
done
exit $status
```
<!-- /snippet -->

The same hook as in video 131. This time read past the `refs/heads/main` case to the part that handles tags: it is another `case` on the ref name, with rules for refs under `refs/tags/`. A tag ruleset is the same mechanism with a different target.

```bash
git tag -a v1.0.0 -m "ticket-router 1.0.0" main~1
git push origin v1.0.0
```

**[ANIMATION]** remotes: id=tagdemo [your clone] A-B main; A atag:v1.0.0#13ad80e; HEAD=main || [the server] A-B main; A atag:v1.0.0#13ad80e; HEAD=none => [your clone] A-B main; B atag:v1.0.0#d68a79d; HEAD=main; cmd:git_tag_-f_-a_v1.0.0_main || [the server] A-B main; A atag:v1.0.0#13ad80e; HEAD=none; say:remote_rejected:_restrict_updates,_then_restrict_deletions; name:disagree => [your clone] A-B main; B atag:v1.0.0#d68a79d; HEAD=main || [the server] A-B main; B atag:v1.0.0#d68a79d; HEAD=none; cmd:!git_push_--force_origin_v1.0.0; say:The_hook_is_switched_off:_the_published_name_now_means_another_commit; name:forced fly=off title=v1.0.0_was_tagged_at_main~1

**[ANIMATION]** step: state-1

A new label on the server: a release tag is created and pushed, one commit behind `main`. Creation is open.

**[ANIMATION]** end

Now the supply-chain mistake: moving a published tag. `git tag -f` moves it locally. `git push --force` would move it on the server. The five answers for that push. It replaces the tag on the server. It destroys the guarantee that the name means one commit, for everyone who fetches from now on. Preview with `git ls-remote --tags origin` against your local tag. Recovery is to push the old tag object back, if someone still has it. And it is appropriate essentially never for a published release tag.

```bash
git tag -f -a v1.0.0 -m "ticket-router 1.0.0" main
git push --force origin v1.0.0
git push origin --delete v1.0.0
```

**[PAUSE]** Two ref updates on a protected tag: a forced move, then a deletion. Which rule refuses each?

<!-- snippet: ch18/ref-updates/08-tags -->
```text
$ git tag -a v1.0.0 -m "ticket-router 1.0.0" main~1
$ git push origin v1.0.0
To ../../server/ticket-router.git
 * [new tag]         v1.0.0 -> v1.0.0
# Moving a published tag, the supply-chain mistake of Chapter 14B:
$ git tag -f -a v1.0.0 -m "ticket-router 1.0.0" main
Updated tag 'v1.0.0' (was 13ad80e)
$ git push --force origin v1.0.0
remote: rule 'restrict updates': refs/tags/v1.0.0 already exists and may not move        
To ../../server/ticket-router.git
 ! [remote rejected] v1.0.0 -> v1.0.0 (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push origin --delete v1.0.0
remote: rule 'restrict deletions': refs/tags/v1.0.0 may not be deleted        
To ../../server/ticket-router.git
 ! [remote rejected] v1.0.0 (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

The move is refused by "restrict updates": the tag already exists and may not move. The deletion is refused by "restrict deletions". Both lines say "remote rejected". Your local tag, by the way, has moved: the transcript says "Updated tag", with the old ID.

**[ANIMATION]** step: tagdemo.disagree

The server still has the original. Your clone and the server now disagree about `v1.0.0`, and that is yours to repair locally. Next, the hook is switched off, like a ruleset set to Disabled. Predict what the same forced push does now. Say it out loud.

**[PAUSE]**

```bash
chmod -x ../../server/ticket-router.git/hooks/pre-receive
git push --force origin v1.0.0
```

<!-- snippet: ch18/ref-updates/09-disabled-again -->
```text
# Enforcement status "disabled": the same force push goes through.
$ chmod -x ../../server/ticket-router.git/hooks/pre-receive
$ git push --force origin v1.0.0
hint: The 'hooks/pre-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
To ../../server/ticket-router.git
 + 13ad80e...d68a79d v1.0.0 -> v1.0.0 (forced update)
```
<!-- /snippet -->

With enforcement "disabled", the same forced tag push goes through: "forced update".

**[ANIMATION]** step: tagdemo.forced

One switched-off ruleset, and a published version name now means a different commit.

**[TERMINAL]** Test the target pattern before you rely on it.

```bash
labs/run ch18/fnmatch-targets
```

```bash
/usr/bin/ruby match.rb "v*" v1.0.0 v2 version-notes release/v1
/usr/bin/ruby match.rb "v[0-9]*" v1.0.0 version-notes
```

**[PAUSE]** A tag ruleset targets `v*`. Is a tag named `version-notes` covered? Is `release/v1`?

<!-- snippet: ch18/fnmatch-targets/04-tags -->
```text
$ /usr/bin/ruby match.rb "v*" v1.0.0 v2 version-notes release/v1
v*             v1.0.0                 match
v*             v2                     match
v*             version-notes          match
v*             release/v1             -
$ /usr/bin/ruby match.rb "v[0-9]*" v1.0.0 version-notes
v[0-9]*        v1.0.0                 match
v[0-9]*        version-notes          -
```
<!-- /snippet -->

`version-notes` is covered, and `release/v1` is not. `v[0-9]*` is the tighter target for version tags.

**[ON SCREEN]** GitHub walkthrough, on your practice repository, following Lab 23.1 for where rulesets are managed. The interface changes; the lab text and the documentation pages on creating rulesets are the reference. No output is shown.

Open the repository's settings and the page that lists rulesets. From Lab 23.1 you have one branch ruleset there. Three things to find on this page. First, the control that creates a new ruleset offers a choice of kind: branch or tag, and on a plan that has them, push as well. Second, look on the neighbouring settings page for classic branch protection rules: when you inherit a repository, that is the first place to look, because a classic rule is invisible to non-administrators. Third, the public view:

```bash
gh ruleset list
gh ruleset check main
```

According to the documentation, anyone with read access can view a repository's active rulesets. Classic rules do not appear there.

Then create the tag ruleset as section 18.12 describes: kind tag, target `v[0-9]*` or `v*` after you have tested the pattern, with restrict updates, restrict deletions and block force pushes, enforcement Active, bypass list empty. Test it as the replay did, with a throwaway version tag: push it, try to move it, try to delete it, and predict the words of each refusal first.

Push rulesets and organization rulesets are not on this page in a public repository of a Free organization. For those, read the documentation pages cited in sections 18.12 and 18.13. That is how the course teaches them.

## COMMON MISTAKES

Five mistakes to watch for.

1. Assuming a classic rule binds administrators. Root cause: under classic protection, restrictions do not apply to people with admin permissions unless "Do not allow bypassing the above settings" is selected.
2. Protecting `main` and leaving release tags unprotected. Root cause: branch rulesets target `refs/heads/`; a tag is a different ref and needs a tag ruleset.
3. Converting a classic rule and keeping it. Root cause: the new ruleset is Active at once and is enforced alongside the classic rule, so changes must satisfy both.
4. Planning to block large files in a public repository on a Free organization with a push ruleset. Root cause: push rulesets need the Team plan and a private or internal repository.
5. Trusting a tag target pattern without testing it. Root cause: `*` does not cross a slash and matches more names than version tags.

## PRODUCTION EXAMPLE

**[ANIMATION]** walk: id=audit columns=door,what_the_team_does rows=main:bind_administrators,_convert_the_classic_rule,_then_remove_it|release_tags:a_tag_ruleset_on_v[0-9]*,_the_release_app_may_create|content_of_pushes:a_push_ruleset:_no_*.ckpt,_*.safetensors,_*.parquet,_a_size_ceiling|the_organization:one_ruleset_by_custom_property,_one_repository_first mono=off title=Per_ref,_what_is_actually_enforced

**[ANIMATION]** step: header

Now, out of the lab. After the force push in the hook, an ML infrastructure team answers the CTO's question: they write down, per ref, what is actually enforced.

**[ANIMATION]** step: 1

For `main`: one classic rule, administrators not bound, and since last month a ruleset. They select the classic setting that binds administrators as an immediate fix, then convert the classic rule with the conversion tool, check with `gh ruleset check main` that the resulting ruleset covers what the old rule did, note that conversation resolution is the one setting the tool does not carry over, and remove the classic rule so that only one mechanism is left to reason about.

**[ANIMATION]** step: 2

For release tags: nothing. They add a tag ruleset on `v[0-9]*` with updates, deletions and force pushes restricted, and a bypass entry for the release automation's app on creation only.

**[ANIMATION]** step: 3

For content: they would like "no `*.ckpt`, `*.safetensors` or `*.parquet` in Git" and a size ceiling well below GitHub's hard 100 MiB, so that large files go to Git LFS or to object storage. That is the textbook's own example of a push ruleset for an ML team. Their production repositories are private on the Team plan, so it is available to them. In the public practice organization of this course it is not.

**[ANIMATION]** step: 4

And at the organization level, on their plan, one ruleset targets every repository with a given custom property. The textbook describes that roll-out as a chain inferred from documented pieces, not as one documented procedure, and they treat it that way: one repository first.

## PRACTICE EXERCISE

Your turn. Do Exercise 23.2, "Which branches does the pattern cover?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). For every pattern and every ref name, write "match" or "no match" before you test anything, and mark the cells where you were unsure. Then test the unsure ones with the `match.rb` script from `labs/run ch18/fnmatch-targets`, and with `gh ruleset check` on your practice repository.

The challenge is Exercise 23.8, "Main is protected. How did a force push get through?", in the same file.

## INTERVIEW QUESTION

Question 252 of the CTO question bank:

> "Classic rule versus ruleset: name four behavioral differences that matter during an incident."

**[PAUSE]**

Answer out loud. A strong answer chooses differences that change what you check first when something got through or something is blocked: who is bound, who can see the rule, how many rules apply to a branch and how they combine, and how each is switched off. For each difference it says what an investigator does differently. It mentions that both mechanisms can be active on the same branch.

## RECAP

Let's land this. "Is it protected?" is no longer a question you accept. You ask: which ref, which update, which actor.

You should now be able to say:

- A tag ruleset with updates, deletions and force pushes restricted keeps a release tag from moving; test the target pattern, because `*` does not cross a slash.
- A push ruleset restricts file paths, path lengths, extensions and sizes for every push and for the fork network, on the Team plan in private or internal repositories.
- An organization ruleset targets many repositories; repository administrators can add to it and cannot weaken it.
- A classic rule applies one at a time, is visible to administrators only, and does not bind administrators by default; it is evaluated alongside rulesets.
- In a public repository of a free organization you can practise branch and tag rulesets; the rest is learned from the documentation.

## HOMEWORK

Read sections 18.12 to 18.15 of [Chapter 18](../../textbook/ch18-branch-protection.md).

That closes the three videos on rules, and you can now audit a repository's protection ref by ref. Practise with Exercise 23.2. Next: seeing and managing rules, and "why can't I merge". Until then, look at the state first and type second. See you in the next one.

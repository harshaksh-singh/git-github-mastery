# V131: What a rule is, rulesets, layering, and bypass

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 26
- **Prerequisites.** V041, V115
- **Textbook sections.** [Chapter 18](../../textbook/ch18-branch-protection.md), sections 18.1 to 18.5
- **Demo scripts.** `labs/ch18/ref-updates.sh`, `labs/ch18/fnmatch-targets.sh`; GitHub-side walkthrough of Lab 23.1

## HOOK

**[ON SCREEN]** "`main` is protected." — and a reflog-less history that lost four commits last night.

After an incident, three sentences from a CTO, straight from the first page of Chapter 18.

"`main` is protected. How did a force push get through?"

"The pull request has two approvals and every check is green. Why is the merge button grey?"

"Who is allowed to skip our rules, and would we know if they did?"

All three have precise answers, and none of them requires guessing what GitHub did. A rule is a small, mechanical thing: a condition checked on the server before a ref moves. A ref is a name for a commit, such as a branch or a tag. Once you see a rule that way, "how did it get through" becomes a list of four things to check, in order. Hold on to the three questions. Each one gets its answer before the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. The pull request chapter ended with a list of controls that are only advisory: a "changes requested" review, a red check, a CODEOWNERS file. This module is about the layer that makes them binding.

On GitHub in 2026 that layer has two mechanisms that coexist: rulesets and classic branch protection rules. Most "why can't I merge" tickets come from not knowing that both are evaluated. The chapter teaches rulesets first, because GitHub now says so: "Rulesets are the recommended way to protect your branches".

This video covers what a rule is, what a ruleset is, how several of them combine, and who can skip them. This is GitHub, not Git: the rules live on the platform.

**[ANIMATION]** sandbox: steps=room,inside name=A_model_of_the_server inside=a_bare_repository_as_the_server,a_pre-receive_hook,five_imitated_rules title=The_mechanism,_modelled_in_plain_Git

But the mechanism can be modelled in plain Git, and that is the demonstration: `labs/ch18/ref-updates.sh`. Inside the lab, a bare repository plays the server and a hook written for the course imitates five rules. It is not GitHub's implementation. The second replay, `labs/ch18/fnmatch-targets.sh`, runs the documented pattern-matching function. Then a walkthrough of Lab 23.1.

**[ANIMATION]** end

Labels. `git push --force` to a shared branch is 🔴 DANGEROUS: it removes commits from the remote branch. Preview with `git log` between your branch and the remote-tracking branch in both directions. In the replay it is aimed at a sandbox server, mostly to be refused. On the GitHub side, the lab creates a ruleset with `gh api --method POST`, which the chapter's table labels 🔴, for a reason I will read out when we get there. `gh ruleset list` and `gh ruleset check` are 🟢 SAFE.

## LEARNING OBJECTIVES

After this video you can:

- Describe a rule as a check on a ref update and say which rules need only the old ID, the new ID and the ref name.
- Reproduce force-push, deletion and merge-commit rules on a local server with a hook.
- Say what a ruleset targets and what its three enforcement statuses do.
- Compute the effective requirement when several rulesets and a classic rule apply.
- Distinguish bypass from exemption and say what trace each leaves.

## CONCEPT

**[ANIMATION]** push: id=rule src=main dst=main refspec=(old,new,refs/heads/main) names=your_clone,the_server gates=your_Git_(--force),the_server's_rules client=pass server=stop notes=--force_switches_off_only_this_check,a_rule_refuses_the_ref_update result=!_[remote_rejected] title=A_rule_is_checked_on_the_server,_before_a_ref_moves

**[ANIMATION]** step: client

In one sentence: a rule is a condition that GitHub evaluates on its server before it lets a ref move, and neither your client nor your `--force` flag has a say in it.

**[ANIMATION]** step: result

Precisely. Every change to a repository on a server is a ref update: a ref name, the old object ID, the new one. A push proposes ref updates. A merge button is GitHub performing one. In the remotes videos you saw the plain-Git hook that sees each proposal first, `pre-receive`: a program the server runs before any ref moves.

Five ruleset rules are predicates on those three values.

**[ON SCREEN]** The table of section 18.2.

Restrict creations: is the old ID all zeros? Restrict deletions: is the new ID all zeros? Block force pushes: is old not an ancestor of new? Require linear history: does the range from old to new contain a commit with two parents? Restrict updates: are both IDs non-zero, that is, does an existing ref move?

The remaining rules, a pull request, approvals, status checks, signatures, ask about GitHub objects attached to the new commits. They need the platform's database, which is why plain Git cannot imitate them.

**[ANIMATION]** cards: id=ruleset question=A_ruleset:_a_named_list_of_rules,_and_three_more_things cards=a_target:which_refs|an_enforcement_status:on_or_off|a_bypass_list:who_is_excepted

Rulesets. In one sentence: a ruleset is a named list of rules with three more things. A target: which refs. An enforcement status: on or off. And a bypass list: who is excepted. You can have up to 75 rulesets per repository, and 75 organization-wide rulesets.

**[ANIMATION]** cards: id=kinds question=Three_kinds_of_ruleset cards=branch_ruleset:branches_by_name_pattern,_or_the_default_branch|tag_ruleset:tags_by_name_pattern|push_ruleset:every_push:_file_paths,_extensions,_sizes dim=2,3 at_1=8 at_2=40 at_3=58

**[ANIMATION]** step: 3

There are three kinds. A branch ruleset targets branches by name pattern, or "the default branch". A tag ruleset targets tags by name pattern. A push ruleset applies to every push to the repository and its fork network, and blocks file paths, extensions and sizes. The last two are the subject of the video after next.

Target patterns use `fnmatch` syntax, and GitHub names the exact function and flag. The consequence, in its words: "the `*` wildcard does not match directory separators".

Try it now, thirty seconds, on paper. The pattern is `qa/*`. Does it cover a branch named `qa/foo/bar`? Write yes or no, and why. I'll wait.

**[PAUSE]**

**[ANIMATION]** walk: id=target columns=target_pattern,branch_name,covered? rows=qa/*:qa/foo:yes,_a_single_slash|qa/*:qa/foo/bar:no,_and_nothing_tells_you marks=1.3:ok,2.3:bad at_1=8 at_2=30 title=The_star_does_not_match_a_slash

No. `qa/*` matches branches beginning with `qa/` and containing a single slash, and does not match `qa/foo/bar`. A pattern that silently fails to match leaves a branch unprotected, with nothing to tell you. In the REST API two special targets exist, `~DEFAULT_BRANCH` and `~ALL`. Prefer the first for `main`: it follows a renamed default branch.

**[ANIMATION]** end

Enforcement status. The documentation for Free, Pro and Team lists two: Active, "your ruleset will be enforced upon creation", and Disabled. The Enterprise Cloud documentation adds Evaluate: the ruleset is not enforced, but you can monitor on the Rule Insights page which actions would or would not violate rules. One caveat marked unverified: whether Evaluate mode is available to Team-plan organization rulesets is not stated.

A disabled ruleset protects nothing and still looks reassuring in a settings page. Disabling is how rulesets get "temporarily" switched off during an incident and forgotten.

**[ANIMATION]** layers: id=layering probe=a_merge_into_main layers=organization_ruleset:block_force_pushes+1_approval|repository_ruleset_A:signed_commits+3_approvals|repository_ruleset_B:required_check_"ci"|classic_rule_on_main:linear_history+2_approvals result=no_force_push+signed_commits+"ci"_green+linear_history+3_approvals rule=a_merge_must_satisfy title=No_priority_order:_the_layers_add_up

**[ANIMATION]** step: 4

Layering. In one sentence: rulesets have no priority order. All active rulesets that target a ref, and the classic rule that matches it, are added together, and for each rule the strictest version wins. The documentation: "A ruleset does not have a priority ... the rules in each of these rulesets are aggregated. If the same rule is defined in different ways across the aggregated rulesets, the most restrictive version of the rule applies."

**[ANIMATION]** step: result

Two consequences. You cannot loosen a branch by editing one layer. And a repository ruleset can add to an organization ruleset and never subtract. One more fact: forks do not inherit branch or tag rulesets from their upstream. They do inherit push rulesets.

**[ANIMATION]** end

Bypass. In one sentence: a ruleset applies to everyone, administrators included, except the actors on its bypass list.

Eligible for the list are repository admins, organization owners and enterprise owners. The maintain or write role. Teams, excluding secret teams. GitHub Apps. Dependabot. And, since the seventh of May 2026, individual users. Each entry has a mode.

**[ON SCREEN]** The three modes of section 18.5.

`always`: the actor may push directly and merge despite the rules, and a bypass is recorded. `pull_request`: the actor must open a pull request, and may then merge it despite unmet rules. That leaves, in GitHub's words, "a clear trail of their changes in the pull request and audit log". `exempt`: the rules are not run for this actor, and no trace is left: "a bypass audit entry will not be created". The exempt mode arrived on the tenth of September 2025. GitHub's own contrast: a standard bypass is "a 'break glass' action" that "generates prominent audit signals", whereas "an exemption silently skips enforcement".

**[ANIMATION]** cards: id=quiz question=Which_mode_lets_someone_skip_the_rules_without_your_ever_knowing? cards=A,_always|B,_pull__request|C,_exempt marks=3:ok

**[ANIMATION]** step: 3

Quick quiz. Which mode lets someone skip the rules without your ever knowing? A: `always`. B: `pull_request`. C: `exempt`. Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

C. And that answers the CTO's third question. With an empty bypass list nobody can skip the rules, including the repository's administrators. With `pull_request` bypass you would know. With `exempt` you would not.

**[ANIMATION]** end

And a point that surprises people who know classic protection: the Maintain role's documented right to push to protected branches does not apply to rulesets. Under rulesets, roles grant nothing by themselves. Only the bypass list does.

**[ANIMATION]** end

## MENTAL MODEL

The textbook's analogy: a bank teller will move money between accounts for anyone with the right card, but checks each transfer against the account's conditions first: two signatures above a limit, no withdrawals from a frozen account. The card is your write permission. The conditions are the rules.

The analogy breaks in one place: on GitHub the conditions are published, and anyone who can read the repository can read them.

**[ANIMATION]** step: layering.result

**[ANIMATION]** say: Several sheets of conditions: all of them apply, and the strictest version of each

Keep the two apart in every incident. "She has write access" is about the card. "The push was refused" is about a condition. And several sheets of conditions can be attached to the same account: the teller applies all of them, and for each condition the strictest version.

**[ANIMATION]** end

## DIAGRAM

**[DIAGRAM]** A push, from your clone to the decision.

```text
  your clone                                   the server (GitHub)
  git push origin main      ---- proposes --->  (old, new, refs/heads/main)
                                                      |
                                                      v
                                          every ACTIVE ruleset that targets the ref
                                          + the classic rule that matches the branch
                                                      |
                                    all rules pass    |    one rule fails
                                  ref moves  <--------+-------->  ! [remote rejected]
                                                                  (bypass actors excepted)
```

On the left, your push. It proposes one thing: old ID, new ID, ref name. On the right, the server collects every active ruleset that targets the ref, plus the classic rule that matches the branch. If all rules pass, the ref moves. If one fails, the push is rejected, and the words are "remote rejected".

Four words in that picture are the four checks for the CTO's first question, "how did a force push get through". Was the ruleset active at that time? Did it target that branch name? Was the actor on a bypass list? And was the rule in the ruleset at all?

**[ANIMATION]** step: layering.result

**[DIAGRAM]** Layering, from section 18.4.

```text
  organization ruleset   : block force pushes, 1 approval
  repository ruleset A   : signed commits, 3 approvals
  repository ruleset B   : required check "ci"
  classic rule on main   : linear history, 2 approvals
  ---------------------------------------------------------------------------
  what a merge into main must satisfy: no force push, signed commits, "ci" green,
                                       linear history, 3 approvals
```

Four layers. Add up every rule, and where one rule appears more than once, approvals at 1, 3 and 2, take the strictest: three. That is the grey merge button with two approvals: some layer that nobody was looking at asks for a third.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch18/ref-updates
```

```bash
cat rules/pre-receive
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

The hook. Read the comment at the top: standard input has one line per proposed ref update, old ID, new ID, ref name. Everything the five rules need is on that line. The `case` statement is the target: `refs/heads/main`.

<!-- snippet: ch18/ref-updates/02-install -->
```text
# Install the rules on the server. Not executable yet: the "ruleset" exists but is disabled.
$ cp rules/pre-receive server/ticket-router.git/hooks/pre-receive
$ cd you/ticket-router
$ git commit -q --allow-empty -m "Start the 1.1 cycle"
$ git push origin main
hint: The 'hooks/pre-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
To ../../server/ticket-router.git
   9aa221a..4e1f5fe  main -> main
# Now active:
$ chmod +x ../../server/ticket-router.git/hooks/pre-receive
```
<!-- /snippet -->

**[ANIMATION]** graph: 9aa221a-4e1f5fe main; HEAD=main => 4e1f5fe-810dc2f main; HEAD=main => 810dc2f-8c7e96f main; HEAD=main title=The_server's_main:_only_accepted_updates_move_it

**[ANIMATION]** step: state-1

Installing it on the bare server and making it executable is "creating a ruleset and setting it to Active". Here is the branch `main` on that server.

```bash
git commit -q -m "Open the changelog for 1.1"
git push origin main
```

<!-- snippet: ch18/ref-updates/03-fast-forward-allowed -->
```text
$ printf '# Changelog\n\n## 1.1 (unreleased)\n' > CHANGELOG.md && git add CHANGELOG.md
$ git commit -q -m "Open the changelog for 1.1"
$ git push origin main
To ../../server/ticket-router.git
   4e1f5fe..810dc2f  main -> main
```
<!-- /snippet -->

**[ANIMATION]** step: state-2

A fast-forward still goes through. No rule asks anything a fast-forward fails.

**[ANIMATION]** end

Now the force push. The five answers for `git push --force` to a shared branch. It replaces the remote branch with yours. It can destroy commits on the server that your branch does not contain. Preview with `git log` between the remote-tracking branch and your branch, in both directions. Recovery is the subject of the recovery chapter and needs the old ID from someone's clone or reflog. And it is appropriate on a shared branch essentially never. Here the target is a sandbox, and the point is the refusal.

```bash
git commit -q --amend -m "Open the changelog for 1.1.0"
git push --force origin main
git push --force-with-lease origin main
```

**[PAUSE]** The server blocks force pushes. `--force` will be refused. What about `--force-with-lease`?

<!-- snippet: ch18/ref-updates/04-force-push -->
```text
$ git commit -q --amend -m "Open the changelog for 1.1.0"
$ git push --force origin main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git push --force-with-lease origin main
remote: rule 'block force pushes': the update would remove commits from refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git reset -q --hard origin/main
```
<!-- /snippet -->

Refused as well. Read the two rejections. "Remote rejected" means the server said no, as opposed to plain "rejected", which is your own Git refusing. `--force-with-lease` fared no better than `--force`: both only switch off client checks.

**[ANIMATION]** step: state-2

And on the server, `main` has not moved. It is still at `810dc2f`. Next, a deletion. Predict which rule answers. Say it out loud.

**[PAUSE]**

```bash
git push origin --delete main
```

<!-- snippet: ch18/ref-updates/05-delete -->
```text
$ git push origin --delete main
remote: rule 'restrict deletions': refs/heads/main may not be deleted        
To ../../server/ticket-router.git
 ! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
```
<!-- /snippet -->

Restrict deletions. Deletion is a ref update too: the new ID is all zeros.

```bash
git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing
git push origin main
git reset -q --hard origin/main
git merge -q --squash feature/priority-routing
```

**[PAUSE]** The linear-history rule is active. A merge commit is pushed, then a squash commit. Which is accepted?

<!-- snippet: ch18/ref-updates/06-merge-commit -->
```text
# A merge commit, the result of the "Create a merge commit" method, pushed to main:
$ git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing
$ git push origin main
remote: rule 'require linear history': the update adds a merge commit to refs/heads/main        
To ../../server/ticket-router.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../../server/ticket-router.git'
[exit status: 1]
$ git reset -q --hard origin/main
# The squash method produces one ordinary commit, which the rule accepts:
$ git merge -q --squash feature/priority-routing
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
$ git commit -q -m "Route high-priority tickets to an escalations queue (#1)"
$ git push origin main
To ../../server/ticket-router.git
   810dc2f..8c7e96f  main -> main
```
<!-- /snippet -->

The merge commit is refused. The squash commit, an ordinary one-parent commit, is accepted. That is the whole content of GitHub's sentence that under this rule pull requests "must use a squash merge or a rebase merge". The `git reset --hard` in between discards the local merge commit in a clean sandbox working tree.

**[ANIMATION]** step: state-3

So `main` moves once more, to `8c7e96f`. Every accepted update is on this line, and the refused ones left no mark.

<!-- snippet: ch18/ref-updates/07-other-branches -->
```text
# The rules target main. Another branch may still be rewritten and deleted:
$ git push -q origin main:refs/heads/scratch
$ git push --force origin main~1:refs/heads/scratch
To ../../server/ticket-router.git
 + 8c7e96f...810dc2f main~1 -> scratch (forced update)
$ git push origin --delete scratch
To ../../server/ticket-router.git
 - [deleted]         scratch
```
<!-- /snippet -->

The rules target `main`. Another branch, `scratch`, may still be rewritten and deleted. A rule protects the refs its target names, and no others.

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

And enforcement status "disabled": the executable bit is removed, and the same kind of force push goes through. Git even prints a hint that the hook was ignored. GitHub's settings page prints no such hint on your push.

**[TERMINAL]** Target patterns. GitHub names a Ruby function, and macOS ships a Ruby, so the documented behaviour can be run.

```bash
labs/run ch18/fnmatch-targets
```

<!-- snippet: ch18/fnmatch-targets/01-script -->
```text
$ cat match.rb
# usage: ruby match.rb PATTERN NAME...
pattern, *names = ARGV
names.each do |name|
  hit = File.fnmatch(pattern, name, File::FNM_PATHNAME)
  puts format("%-14s %-22s %s", pattern, name, hit ? "match" : "-")
end
```
<!-- /snippet -->

```bash
/usr/bin/ruby match.rb "qa/*" qa/login qa/login/retry qa
/usr/bin/ruby match.rb "qa/**/*" qa/login qa/login/retry qa/a/b/c
```

<!-- snippet: ch18/fnmatch-targets/02-star-stops-at-slash -->
```text
$ /usr/bin/ruby match.rb "qa/*" qa/login qa/login/retry qa
qa/*           qa/login               match
qa/*           qa/login/retry         -
qa/*           qa                     -
$ /usr/bin/ruby match.rb "qa/**/*" qa/login qa/login/retry qa/a/b/c
qa/**/*        qa/login               match
qa/**/*        qa/login/retry         match
qa/**/*        qa/a/b/c               match
```
<!-- /snippet -->

`qa/*` matches one level. `qa/**/*` matches any number of slashes.

```bash
/usr/bin/ruby match.rb "release/*" release/1.0 release/1.0/hotfix releases/1.0
/usr/bin/ruby match.rb "*feature*" feature-x my-feature feature/x team/feature/x
```

**[PAUSE]** `*feature*`. Does it protect a branch called `feature/x`?

<!-- snippet: ch18/fnmatch-targets/03-common-targets -->
```text
$ /usr/bin/ruby match.rb "release/*" release/1.0 release/1.0/hotfix releases/1.0
release/*      release/1.0            match
release/*      release/1.0/hotfix     -
release/*      releases/1.0           -
$ /usr/bin/ruby match.rb "*feature*" feature-x my-feature feature/x team/feature/x
*feature*      feature-x              match
*feature*      my-feature             match
*feature*      feature/x              -
*feature*      team/feature/x         -
$ /usr/bin/ruby match.rb "**/*" main feature/x a/b/c
**/*           main                   match
**/*           feature/x              match
**/*           a/b/c                  match
$ /usr/bin/ruby match.rb "*" main feature/x
*              main                   match
*              feature/x              -
```
<!-- /snippet -->

It does not, although the documentation uses that very pattern as an example of "any branches matching": the star stops at the slash. `release/*` does not cover `release/1.0/hotfix`. And a star alone matches no branch that has a slash in its name.

**[ON SCREEN]** GitHub walkthrough, Lab 23.1 Part B, in the normal shell, on the lab's starter repository. The interface changes; the lab text and the documentation pages on rulesets are the reference. No output is shown.

The lab creates the ruleset from a JSON file kept in the course, through the REST API. The chapter's safety table labels that call 🔴, and gives the reason: it destroys nothing, but every `gh api` call that is not a `GET` does whatever the endpoint and the JSON say, with all your permissions. And if the ruleset is Active, it binds everyone at once, you included. The preview is to create it with enforcement disabled and run `gh ruleset check`. The recovery is to set enforcement to disabled again. It is appropriate for rules kept as reviewed JSON, which is what the lab file is. Read the file before you send it.

```bash
cat "$COURSE/labs/ch18/rulesets/lab-23-1-main.json"
gh api --method POST "repos/$ORG/ticket-router-lab/rulesets" --input "$COURSE/labs/ch18/rulesets/lab-23-1-main.json"
gh ruleset list
gh ruleset check main
gh ruleset check main --web
```

`gh ruleset check main` asks GitHub which rules apply to that branch name. With `--web` it opens the same answer in the browser. In the repository's settings, the rulesets page lists the ruleset with its enforcement status, its target and its bypass list. Name what you see there by those three words.

Then test it as the replay did:

```bash
git commit --allow-empty -m "Direct push attempt"
git push origin main
git reset --hard origin/main
git push --force origin main~1:main
```

Predict each answer before you run it, including the words "remote rejected". The lab then goes the allowed way, through a pull request, and tries two merge methods against the ruleset. Its local Part A also shows layering with two plain-Git layers: the hook is disabled and the force push is still refused, by the server setting `receive.denyNonFastForwards`.

## COMMON MISTAKES

Five mistakes to watch for.

1. Believing `--force-with-lease` can get past a server rule. Root cause: both force options only switch off client-side checks; the rule is evaluated on the server.
2. Targeting `feature*` or `release/*` and assuming nested branch names are covered. Root cause: the star does not match a slash; a pattern that fails to match protects nothing and says nothing.
3. Loosening one ruleset and finding the merge still blocked. Root cause: all active rulesets and the classic rule are aggregated, and the most restrictive version of each rule applies.
4. Assuming administrators or the Maintain role can push past a ruleset. Root cause: under rulesets only the bypass list grants exceptions.
5. Leaving a ruleset disabled after an emergency. Root cause: a disabled ruleset enforces nothing and still appears in the settings page.

## PRODUCTION EXAMPLE

Now, out of the lab. "How did a force push get through?" An ML platform team answers it in the order the textbook gives.

**[ANIMATION]** cards: id=four question=How_did_a_force_push_get_through? cards=Was_the_ruleset_Active?:Disabled_three_weeks_earlier|Did_it_target_that_branch_name?:the_default_branch:_yes|Was_the_actor_on_a_bypass_list?:a_team,_in_always_mode|Was_the_rule_in_the_ruleset_at_all?:yes numbered=on marks=1:bad,2:ok,3:ring,4:ok

**[ANIMATION]** step: 1

Was the ruleset Active at that time? The ruleset on `main` was set to Disabled three weeks earlier, during a migration, and never switched back. That alone answers the question. They check the other three anyway.

**[ANIMATION]** step: 2

Did it target that branch name? The target was the default branch, so yes. Their second ruleset, for release branches, used `release/*`, and the hotfix branches are named `release/2.4/hotfix-1`: those were never covered.

**[ANIMATION]** step: marks

Was the actor on a bypass list? One entry: a team, in `always` mode. Was the rule in the ruleset at all? Yes.

**[ANIMATION]** end

Their changes follow section 18.5. The bypass list becomes short and is made of roles or teams, not people. Humans get `pull_request` mode, so that an emergency merge still leaves a pull request. `always` is reserved for the one automation that must push, the release bot, under its own GitHub App identity, so that the entry names a thing they can audit. Nobody is `exempt`. And the ruleset JSON goes under version control.

## PRACTICE EXERCISE

Your turn. Do Lab 23.1, "A ruleset on the default branch", in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md). Part A runs in the lab shell on a bare server, and Part B on GitHub. Before each push in Part A, write the three values of the ref update, old, new and ref, and name the rule that will refuse it, or say that none will. In the failure scenario, predict what happens when one of two layers is switched off.

The challenge is Exercise 23.4, "Layers", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 221 of the CTO question bank:

> "What is a rule, mechanically? Which rules can be decided from the old ID, the new ID and the ref name alone, and which need platform data?"

**[PAUSE]**

Answer out loud. A strong answer defines a ref update and where it is evaluated. It lists the rules of the first kind with the question each asks about the three values, and explains for the second kind what the platform has to look up. It mentions what a force flag does and does not change, and how you would model the first kind without GitHub.

## RECAP

Let's land this. Three questions from a CTO came in, and each one now has a mechanical answer.

You should now be able to say:

- A rule is a server-side condition on a ref update: old ID, new ID, ref name.
- Creation, deletion, force push, linear history and update restrictions need only those three values; reviews, checks and signatures need platform data.
- A ruleset has a target, an enforcement status and a bypass list; `*` in a target does not cross a slash.
- All applicable rulesets and the classic rule add up, and the strictest version of each rule holds.
- Bypass leaves a trace; exemption does not; roles alone grant nothing under rulesets.

## HOMEWORK

Read sections 18.1 to 18.5 of [Chapter 18](../../textbook/ch18-branch-protection.md). Do Exercise 23.1, "Five predicates", and Exercise 23.2, "Which branches does the pattern cover?", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

You can now read a refused push as a condition on three values, and say who may skip it. Practise with Lab 23.1. Next: the rules and their sub-options. Until then, look at the state first and type second. See you in the next one.

# V164: Credentials and what a stolen one can reach, and why deleting, force-pushing and going private do not remove a secret

- **Part.** 7: Security
- **Module.** 30
- **Planned minutes.** 26
- **Prerequisites.** V069, V116, V163
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.8 to 21B.11
- **Demo scripts.** `labs/ch21b/find-secret.sh`. The secret in the script is a dummy string made for the lab, spelled so that no scanner pattern matches it.

## HOOK

**[ON SCREEN]** Question 1 of section 21B.1: "A key was in the repository. We deleted it. Are we safe?"

The developer who made the mistake is relieved. They removed the file, added it to `.gitignore`, the list of paths Git shouldn't track, committed and pushed. They search the code: nothing. The repository on GitHub shows no `.env` file. The message in the team channel says: "Removed, sorry about that."

The textbook's judgment on that answer is one sentence: deleting a file adds a commit and removes nothing.

In this video you'll run the developer's exact repair in the sandbox, see the search come back clean, and then print the key from a commit four steps back, and from the server, through a release tag. And you'll learn the only question that decides whether a leaked secret is dangerous, which isn't a question about the repository at all. Hold that thought.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video has two halves that belong together in an incident.

The first half is about the credential, the token or key that proves to a service who is asking. If one leaks, what can the holder reach, and for how long? That depends on its type, and the textbook says most teams can't say which type their automation uses.

The second half is about the repository: why deletion, a forced push, and making the repository private don't remove a secret, and how you measure where it is with three built-in commands.

**[ON SCREEN]** Three layer labels: Git, GitHub, the issuer.

**[ANIMATION]** layers: layers=Git_on_your_machine:what_history_contains|GitHub:what_is_displayed,_scanned,_blocked_and_retained|the_issuer:whether_the_leaked_secret_still_works winner=3 rule=where_incidents_are_decided title=Three_layers id=three at_1=12 at_2=22 at_3=32 at_result=55

The chapter insists on three layers, and you should hold them apart for the rest of this part. Git on your machine: what history contains. GitHub: what is displayed, scanned, blocked and retained. And the issuer of the credential, the service that created it: whether the leaked secret still works. The third layer is the one tutorials leave out, and it's where incidents are decided. A secret is harmless from the moment its issuer revokes it, meaning cancels it, and dangerous until then, whatever you do to the repository.

**[ANIMATION]** end

Every secret in the transcripts is a dummy.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- rank credential types by what a thief can reach with each;
- explain why a secret deleted in a later commit is still in the repository;
- say where a force-pushed-away commit can still be found;
- find a secret in every ref of a repository with built-in commands;
- say which refs and tags contain the secret.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub. The credential table of section 21B.8.

**What a stolen credential can reach.** Seven rows, from narrow to wide.

The Actions `GITHUB_TOKEN`: the workflow's repository, within the job's `permissions`. Lifetime: the job.

A GitHub App installation token: the installation's repositories and permissions. Lifetime: one hour.

A GitHub App private key: it mints installation tokens for every installation of the app. Lifetime: it never expires.

A fine-grained personal access token: one owner, optionally selected repositories, per-permission. Lifetime: configurable.

A deploy key: one repository, read or read-write. Long-lived.

A personal SSH key: everything the account can reach over SSH. Long-lived.

A classic personal access token: every repository and organization its owner can reach, by scope. Long-lived.

Two automatic protections exist, and both are narrow. GitHub revokes its own tokens when they're pushed to a public repository or gist. And it removes tokens unused for a year.

**[ANIMATION]** cards: question=Which_leak_is_worse? cards=A:an_installation_token_that_lives_for_one_hour|B:the_App_private_key_that_mints_such_tokens_and_never_expires marks=1:dim,2:ring id=quiz

**[ANIMATION]** step: quiz.2

Quick quiz. Which leak is worse? A, an installation token that lives for one hour. B, the App private key that mints such tokens and never expires. Your answer?

**[PAUSE]**

**[ANIMATION]** step: quiz.marks

B. The textbook calls the App private key the row people forget, and gives a figure with its source.

**[ANIMATION]** bars: bars=leaked_keys_tested:4802|still_authenticated:474|organization_admin_access:44 title=Leaked_GitHub_App_private_keys,_September_2026_(GitGuardian) id=keys

Of 4,802 leaked GitHub App private keys tested in September 2026, 474 still authenticated, 44 of them with organization admin access, according to GitGuardian. The conclusion: short-lived installation tokens are only as safe as the long-lived key that mints them.

**[ANIMATION]** cards: cards=OIDC-issued_cloud_tokens_and_the_job-scoped_GITHUB__TOKEN:wherever_the_work_happens_inside_a_workflow|GitHub_App_installation_tokens:the_private_key_in_a_secrets_manager|fine-grained_personal_access_tokens:with_an_expiry_and_organization_approval|deploy_keys:read_access_to_a_single_repository|classic_tokens_and_shared_machine_users:with_a_written_reason numbered=on title=A_hierarchy_for_automation_(an_inference,_not_a_GitHub_statement) id=order at_1=22 at_2=38 at_3=52 at_4=66 at_5=78

**A hierarchy for automation.** The Phase 0 report derives an order from those facts. It is marked as an inference, not a GitHub statement. First: OIDC-issued cloud tokens and the job-scoped `GITHUB_TOKEN`, wherever the work happens inside a workflow. Second: GitHub App installation tokens, with the App's private key in a secrets manager. Third: fine-grained personal access tokens with an expiry and organization approval. Fourth: deploy keys, for read access to a single repository. Fifth and last: classic tokens and shared machine users, with a written reason.

**[ANIMATION]** walk: columns=when,what_was_abused,the_lesson rows=April_2022:stolen_OAuth_tokens_issued_to_two_integrators:a_third_party's_token_store_is_part_of_your_attack_surface|December_2022:an_already_authenticated_session,_stolen_by_malware_on_a_laptop:two-factor_authentication_protects_the_login,_not_the_session|May_2026:a_poisoned_third-party_editor_extension_on_an_employee_device:flag:_attribution_and_extension_details_come_from_vendor_reports mono=off title=Tokens,_sessions_and_laptops,_not_Git id=real

**Real compromises abuse tokens, sessions and laptops, not Git.** Three cases from the section. In April 2022, stolen OAuth tokens issued to two integrators were used to clone private repositories of dozens of organizations. The lesson is that a third party's token store is part of your attack surface. In December 2022, malware on an engineer's laptop at a CI provider stole an already authenticated session, bypassing two-factor authentication. The lesson is that two-factor authentication protects the login, not the session that follows it. And in May 2026, a poisoned third-party editor extension on an employee device led to exfiltration of GitHub-internal repositories, and GitHub rotated critical secrets. For that third case the textbook flags that attribution and details of the extension come from vendor reports, and that one vendor gives the detection date as the nineteenth of May where GitHub says the eighteenth of May.

**[ANIMATION]** end

**Token forensics.** After a suspected compromise the question is "what did this token do?". GitHub's audit log, an organization's record of events, can be searched by token without storing the token itself: you compute its SHA-256 and search for the hash.

```bash
# The token is read from a variable, never typed on the command line or pasted into chat.
printf '%s' "$LEAKED_TOKEN" | openssl dgst -sha256 -binary | base64
# then search the audit log for:   hashed_token:"<the value printed above>"
```

Two limits decide whether this works on the day. A search by token hash returns no Git events: clones, fetches and pushes made with the token have to be identified in an export of Git events data. And the retention differs: the organization audit log covers 180 days, while Git events are an Enterprise Cloud feature that the audit log retains for seven days. So to answer "was the repository cloned with this token?" months later, streaming or export must be set up before the incident.

**The scale,** in three figures, each with its source in section 21B.9. GitGuardian counted 28,649,024 new secrets on public GitHub in 2025, up 34 percent. Of them, 1,275,105 were tied to AI services, up 81 percent. 64 percent of the secrets confirmed valid in 2022 were still valid when retested. And internal repositories were about six times more likely than public ones to contain a hardcoded secret. The textbook reads the last two for you: "still valid years later" means that detection without revocation achieves nothing. "Internal repositories are worse" means that privacy is being used as a substitute for hygiene.

**[ON SCREEN]** Lower third: Git.

**Why deletion is not removal. In one sentence:** a commit is a permanent snapshot, so a later commit that deletes a file leaves every earlier snapshot intact, and moving or hiding refs changes who can easily find the old snapshot, not whether it exists. A ref is a name, such as a branch or a tag, that points at a commit.

Three operations are commonly mistaken for removal.

**[ON SCREEN]** The three-row table of section 21B.10.

Commit a deletion. What it changes: it adds a new commit whose tree lacks the file. Where the secret still is: in every commit between the one that added it and the deletion, reachable from the branch, from tags, from other branches.

Amend or reset, then force-push, which makes the server's branch point at different commits. What it changes: it moves a ref to different commits. Where the secret still is: in the old commits, which stay in the server's object database, in every clone and fork that fetched them, and on GitHub in cached views and through pull requests that reference them.

Make the repository private, or delete it. What it changes: who may read through the normal interface. Where the secret still is: in every clone and fork made while it was public, and in the fork network, a repository and all its forks, whose Git data is stored together.

GitHub states the second and the third row itself, and researchers have shown both to be exploitable at scale. In 2024, 40 valid API keys in commits from deleted forks of three commonly forked repositories. And in 2025, commits orphaned by force pushes enumerated from public event archives and scanned, which yielded thousands of secrets.

**[ON SCREEN]** Callout: Root cause. "Private", "deleted" and "force-pushed" change discoverability, not accessibility. The exposure window starts at the first push and does not end at deletion.

**Finding it.** You need three commands, and you need to know what each one can't see.

**[ANIMATION]** walk: columns=command,what_it_lists,the_question_it_answers rows=git_log_-S_string:commits_where_the_number_of_occurrences_changed:where_did_it_enter_and_leave?|git_log_-G_regex:commits_whose_diff_has_a_matching_line:the_shape_of_a_secret,_not_its_value|git_grep,_all_commits:the_content_of_every_commit's_tree:in_which_snapshots_is_it_present?|--contains:branches_and_tags_that_reach_a_commit:what_is_the_scope? title=Three_commands,_and_what_each_one_answers id=find

**[ANIMATION]** step: find.1

`git log -S` with a string, the pickaxe, lists commits in which the number of occurrences of the string changed: the commits that added it and the commits that removed it. Without `--all` it walks only the current branch.

**[ANIMATION]** step: find.2

`git log -G` with a regular expression lists commits whose diff has an added or removed line that matches. Use it when you know the shape of a secret and not its value, and with `--all` to cover every ref.

**[ANIMATION]** step: find.3

`git grep` with a pattern and the list of all commits searches the content of every commit's tree, not the diffs. It answers "in which snapshots is the secret present?", which is the exposure. The pickaxe answers "where did it enter and leave?".

**[ANIMATION]** step: find.4

And to turn a commit into scope: `git branch -a --contains` and `git tag --contains`.

**[ANIMATION]** say: All_of_these_only_read:_they_change_nothing

All of these are 🟢 SAFE: they change nothing.

## MENTAL MODEL

**Analogy,** from the textbook. Publishing a correction in tomorrow's newspaper doesn't recall yesterday's edition from the people who bought it. Withdrawing yesterday's edition from your own archive, which is the force push, doesn't recall it either.

The analogy breaks for unpushed commits: an edition that never left the building can be pulped. That's the next video.

**[ANIMATION]** repos: [your repository] A-B main; mark:the_secret:B; HEAD=none; say:Before_the_first_push:_one_repository,_yours || [the server] A main; HEAD=none || [a fork] A main; HEAD=none || [a clone] A main; HEAD=none => + say:After_the_first_push:_every_repository_that_fetched_it || + A-B main; mark:the_secret:B || + A-B main; mark:the_secret:B || + A-B main; mark:the_secret:B => + say:Revoked_at_the_issuer:_every_copy_is_a_string_that_opens_nothing || || || title=The_dividing_line_is_the_first_push id=push at_state_2=55

**[ANIMATION]** step: push.state-2

So the dividing line is the first push. Before it, the secret exists in one repository, yours, and you can rewrite your own unpushed commits. After it, the secret exists in every repository that fetched those commits, and you control none of them.

**[ANIMATION]** step: push.state-3

Now put the two halves of this video together. After the first push you can't un-publish. What you can do is make the published thing worthless. That happens at the issuer, by revocation, and it works against every copy at once: the one on the server, the one in a fork, the one in a colleague's clone, the one in a log. Nothing you do in Git has that property. So there's the question from the opening: not "is the file gone?", but "does the key still work?"

**[ANIMATION]** end

And how urgent it is depends on the first half: the type of credential. A job token that died with its job an hour ago is one situation. An App private key that never expires is another.

## DIAGRAM

Try it now, thirty seconds, on paper. Write "leaked commit" in the middle of the page. Around it, write every place where a copy of that commit may live. How many can you name? Say them out loud.

**[PAUSE]**

**[ANIMATION]** stores: boxes=commit_0805fd8:tree_contains_.env_(blob_e523d04)|what_each_action_changes rows=1:A:server_branch_main:_the_tip_is_clean;_the_commit_is_an_ancestor|1:A:server_tag_v0.2.0:_still_points_into_the_affected_range|1:A:an_old_pull_request_ref,_and_cached_views_by_commit_ID|1:A:a_fork,_or_the_fork_network,_even_after_the_fork_is_deleted|1:A:two_clones_(teammates,_CI_workspaces),_and_a_CI_log_that_printed_it|2:B:a_deletion_commit:_the_next_snapshot_only@dim|2:B:a_forced_push:_where_one_ref_points@dim|2:B:going_private:_who_may_read_through_the_normal_interface@dim|3:B:the_issuer_of_the_key:_REVOKE@ok|3:B:every_copy_becomes_a_string_that_opens_nothing@ok arrows=3:B4>A:every_copy title=One_leaked_commit,_and_every_place_a_copy_lives id=copies at_1=8 at_2=45 at_3=75

**[ANIMATION]** step: copies.boxes

**[DIAGRAM]** One leaked commit in the middle. Draw each place a copy may live around it, one at a time, and for each say which of the three "repairs" reaches it. At the end, draw the issuer at the bottom, outside all of it.

```text
                                 +---------------------------+
                                 |  commit 0805fd8           |
                                 |  tree contains .env       |
                                 |  (blob e523d04)           |
                                 +-------------+-------------+
                                               |
       +------------------+--------------------+--------------------+-------------------+
       |                  |                    |                    |                   |
  server branch      server tag           an old pull         a fork, or the       two clones
  main: the tip      v0.2.0: still        request ref,        fork network         (teammates,
  is clean; the      points into the      and cached          even after the       CI workspaces),
  commit is an       affected range       views by            fork is deleted      and a CI log
  ancestor                                commit ID                                that printed it

  a deletion commit      changes: the next snapshot only
  a forced push          changes: where one ref points
  going private          changes: who may read through the normal interface

  ----------------------------------------------------------------------------------------------
  the issuer of the key:   REVOKE   ->  every copy above becomes a string that opens nothing
```

**[ANIMATION]** step: copies.3

Compare with the picture. A server branch, a server tag, an old pull request ref and cached views, a fork or the fork network, and clones with a CI log. A deletion commit, a forced push and going private each change one thing, and none of them reaches every copy. Revoking at the issuer does: every copy becomes a string that opens nothing.

**[ON SCREEN]** The root-cause box of section 21B.10, one line at a time. Observed behavior: the key is gone from the files, and a scanner still reports it. Git state: the tip tree has no `.env`; commits `0805fd8` to `d4b8762` have trees that contain blob `e523d04`. Mechanism: `git rm` changes the next snapshot; earlier snapshots are immutable objects. Root cause: the secret was pushed, so it exists in every repository that fetched those commits. Why Git does this: history that could be edited in place could not be verified by its hash. Correct fix: revoke the key at its issuer; then decide whether a history rewrite is warranted. Prevention: keep secrets out of the working tree's tracked paths; block them at commit and at push.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/find-secret`. The fixture is `ragdesk`, a retrieval-augmented helpdesk service, with a bare `server.git` and two teammates' clones. The IDs equal the book's.

**Step 1: the leak.**

```bash
git log --oneline --decorate
cat .env
```

<!-- snippet: ch21b/find-secret/01-the-leak -->
```text
$ cd ragdesk
$ git log --oneline --decorate
d4b8762 (HEAD -> main, origin/main) Document setup in README
b509fe3 Add request timeout
64b9b89 (tag: v0.2.0) Add retry with backoff
0805fd8 Add staging settings
987a49d (tag: v0.1.0) Add evaluation harness
6388058 Add LLM client
0c55276 Add answer prompt template
dfd59fd Add BM25 retriever
$ cat .env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

Into the lab. Eight commits and two tags. Four commits back, in `0805fd8`, "Add staging settings", a `git add -A` swept a local `.env` into the commit. The file holds a dummy key. Notice the tag `v0.2.0` one commit above it.

**Step 2: the usual first reaction.**

```bash
git rm --cached -q .env
printf '.env\n' > .gitignore
git add .gitignore && git commit -q -m 'Stop tracking .env and ignore it'
git ls-files
git grep -n DUMMY-KEY
git show HEAD~4:.env
```

`git rm --cached` is 🟡 CAUTION: it removes the file from the index, and the working tree copy stays. `git commit` is 🟢 SAFE. After this commit: what does `git grep` on the tip say, and what does `git show` of the same path four commits back say? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21b/find-secret/02-delete-is-not-removal -->
```text
$ git rm --cached -q .env
$ printf '.env\n' > .gitignore
$ git add .gitignore && git commit -q -m 'Stop tracking .env and ignore it'
$ git ls-files
.gitignore
README.md
eval.py
llm_client.py
prompts/answer.txt
retriever.py
settings.yaml
$ git grep -n DUMMY-KEY
[exit status: 1]
# The tip is clean. The commit that added the file still has it:
$ git show HEAD~4:.env
LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

The file list has no `.env`. `git grep` finds nothing and exits with status 1. That's what the developer saw, and why they felt safe. And `git show HEAD~4:.env` prints the key. The tip is clean. The commit that added the file still has it.

**[ANIMATION]** graph: dfd59fd-0c55276-6388058-987a49d-0805fd8-64b9b89-b509fe3-d4b8762 main origin/main; dfd59fd-0c55276-6388058-987a49d v0.1.0; 987a49d-0805fd8-64b9b89 v0.2.0; HEAD=main => dfd59fd-0c55276-6388058-987a49d-0805fd8-64b9b89-b509fe3-d4b8762-d42d1a1 main; b509fe3-d4b8762 origin/main; dfd59fd-0c55276-6388058-987a49d v0.1.0; 987a49d-0805fd8-64b9b89 v0.2.0; HEAD=main => + b509fe3-7fae871 origin/feature/streaming; ^987a49d-54093fe origin/exp/rerank; range:0805fd8,64b9b89,b509fe3,d4b8762,7fae871:.env_present; note:54093fe:a_token_in_a_notebook_output; say:The_scope:_every_ref_from_which_the_commit_is_reachable title=A_deletion_adds_a_commit_and_removes_nothing id=leak

**[ANIMATION]** step: state-1

Here's `main` as a picture, before the repair. Eight commits, with `0805fd8` four from the top, and the tag `v0.2.0` right above it.

**[ANIMATION]** step: state-2

The repair is one new commit on top, `d42d1a1`. Nothing below it changed. `0805fd8` still holds the file, and `v0.2.0` still points into the affected range.

**Step 3: where did it enter and leave?**

```bash
git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env
git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'
```

The pickaxe lists commits where the number of occurrences changed. How many commits, and which? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21b/find-secret/03-pickaxe -->
```text
$ git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
$ git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'
d42d1a1 Stop tracking .env and ignore it
0805fd8 Add staging settings
```
<!-- /snippet -->

Two: `0805fd8`, which introduced the key, and `d42d1a1`, which deleted it. Everything between them contains it and isn't listed, because the count didn't change there. Remember that when you read pickaxe output: it shows the edges of the exposure, not the exposure.

```bash
git log -p --format='commit %h%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' -S'DUMMY-KEY-not-a-real-secret' --diff-filter=A
```

<!-- snippet: ch21b/find-secret/04-pickaxe-patch -->
```text
$ git log -p --format='commit %h%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' -S'DUMMY-KEY-not-a-real-secret' --diff-filter=A
commit 0805fd8
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:10:00 2026 +0530

    Add staging settings

diff --git a/.env b/.env
new file mode 100644
index 0000000..e523d04
--- /dev/null
+++ b/.env
@@ -0,0 +1,2 @@
+LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
+LLM_BASE_URL=https://llm.example.com
```
<!-- /snippet -->

With `-p` you see the lines, and with `--diff-filter=A` only commits that added a file, which is the introduction. The textbook's remark: that one transcript answers four assessment questions. Which commit, who, when, and which file.

**Step 4: the shape, not the value.**

```bash
git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
git log --oneline --all --name-only --format='%h %s' -G'Bearer [A-Za-z0-9-]+'
```

A regular expression, a pattern that describes text by its shape, for the family of dummy secrets, over all refs. Do you expect the same two commits? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21b/find-secret/05-regex -->
```text
$ git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
d42d1a1 Stop tracking .env and ignore it
54093fe Add rerank debugging notebook
0805fd8 Add staging settings
$ git log --oneline --all --name-only --format='%h %s' -G'Bearer [A-Za-z0-9-]+'
54093fe Add rerank debugging notebook

notebooks/rerank-debug.ipynb
```
<!-- /snippet -->

Three. The third, `54093fe`, is "Add rerank debugging notebook". The second command shows where: a bearer token captured in the output cell of a notebook, on a branch that was pushed and never merged. Nobody had reported it. Notebook outputs leak secrets that the author never typed.

**Step 5: in which snapshots is it present?**

```bash
git grep -n 'DUMMY-KEY' $(git rev-list --all) | cut -c1-9,41-
git grep -l -E 'DUMMY-(KEY|TOKEN)' $(git rev-list --all) | cut -d: -f2 | sort | uniq -c
```

<!-- snippet: ch21b/find-secret/06-grep-all-commits -->
```text
$ git grep -n 'DUMMY-KEY' $(git rev-list --all) | cut -c1-9,41-
d4b876277:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
7fae87198:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
b509fe363:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
64b9b890c:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
0805fd8e8:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345

# Which files, in how many commits:
$ git grep -l -E 'DUMMY-(KEY|TOKEN)' $(git rev-list --all) | cut -d: -f2 | sort | uniq -c
   5 .env
   1 notebooks/rerank-debug.ipynb
```
<!-- /snippet -->

Five snapshots contain the key. The first column is the commit, shortened by `cut`. Four are on `main`, and one, starting `7fae871`, is on a teammate's branch. Then the summary: `.env` in five commits, the notebook in one. On a large repository the argument list becomes too long for one command. The textbook gives the piped form with `xargs`.

**Step 6: which refs?**

```bash
first=$(git log --all --format=%H --diff-filter=A -- .env)
git branch -a --contains $first
git tag --contains $first
```

<!-- snippet: ch21b/find-secret/07-which-refs -->
```text
$ first=$(git log --all --format=%H --diff-filter=A -- .env)
$ git log --oneline -1 $first
0805fd8 Add staging settings
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
```
<!-- /snippet -->

The local `main`, the remote-tracking `main`, a remote-tracking feature branch, and the tag `v0.2.0`.

**[ANIMATION]** step: leak.state-3

That list is the scope on the Git side: every ref from which the commit is reachable.

**[ANIMATION]** end

**Step 7: the server.**

```bash
git push -q origin main
git -C ../server.git grep -c DUMMY-KEY main
git -C ../server.git grep -n 'DUMMY-KEY' v0.2.0 -- .env
```

`git push` is 🟡 CAUTION. After the deletion commit is pushed: what does the server say about the tip of `main`, and what about the tag? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21b/find-secret/08-server-still-has-it -->
```text
$ git push -q origin main
$ git -C ../server.git grep -c DUMMY-KEY main
[exit status: 1]
$ git -C ../server.git grep -n 'DUMMY-KEY' v0.2.0 -- .env
v0.2.0:.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

The tip of `main`: no match, exit status 1. The tag `v0.2.0`: line 1 of `.env`, with the key. The server agrees on both counts. The tag points into the affected range and serves the file to anyone who fetches it.

**[ON SCREEN]** The table at the end of section 21B.11: what each command finds and does not see. `git grep` on the working tree: nothing in history. The pickaxe: not other branches without `--all`, and not a secret that was moved within a file. `git log --all -G`: not commits that no ref reaches. `git grep` over all commits: not commits no ref reaches, and not binary and compressed files. The same with `--all --reflog`: also commits reachable only from reflogs, but not unreachable objects without reflog entries, and not other people's clones.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Saying "I removed it" after a deletion commit.** Root cause: `git rm` changes the next snapshot; every earlier snapshot is an immutable object and still contains the file.
2. **Checking only the tip, or only the current branch.** Root cause: `git grep` without commits searches the working tree's tracked files, and the pickaxe without `--all` walks one branch; tags and other branches still reach the commit.
3. **Force-pushing and considering the commit gone.** Root cause: a forced push moves a ref; the old commits stay in the server's object database, in clones and forks, in cached views and behind pull requests.
4. **Making the repository private as a response.** Root cause: that changes who may read from now on, not what was fetched while it was public or what the fork network holds.
5. **Adding the file to `.gitignore` and stopping there.** Root cause: ignoring a tracked file changes nothing; and neither step touches whether the key still works at its issuer.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's description of how these leaks happen in your field: an LLM key is created in a browser tab, pasted into a notebook or a `.env`, and committed by `git add -A` or by an agent that stages everything it touched.

Take that as an incident on an AI team. Monday, an engineer commits a `.env` with a provider key. Wednesday, they notice, delete the file in a new commit, and push. Friday, a scanner run by someone outside the company reports the key as valid.

**[ANIMATION]** replay: push

What the team should have asked on Wednesday isn't "is the file gone?" but two other things. First, at the issuer: is the key revoked? It wasn't. Nobody thought of the provider's console, because the repository looked clean. Second, in Git: which commits, which refs? With the three commands the answer takes two minutes, and in a case like the demonstration it includes a release tag and a colleague's branch.

**[ANIMATION]** end

And one more question, from the first half: what type of credential was it, and what can it reach? A provider key with no expiry and full account scope is the wide end of the table.

## PRACTICE EXERCISE

Your turn. Do Lab 30.3, "Scan a full history for planted secrets", in [`lab-manual/m30-repository-security.md`](../../lab-manual/m30-repository-security.md), in `labs/shell`. Your IDs differ from the video.

Before each of the five scans, predict what it can and can't see, from the table. After the pickaxe, predict how many snapshots the all-commits search will report, and then compare. Write down the scope as a list of refs.

The challenge is Exercise 30.5, "Six leaked credentials", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q327: "Rank the credentials an automation could use to push to a repository by blast radius, and justify the order."

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer ranks by two things at once, reach and lifetime, and gives both for each credential it places. It says where the ranking comes from and that it is an inference from documented facts. It doesn't forget the credential that mints other credentials. The follow-up says an installation token lives for one hour and asks why "we use a GitHub App" isn't the end of the conversation. Answer with the row people forget and the figures the chapter cites, with their source.

## RECAP

Let's land this.

You should now be able to say:

- A credential's danger is its reach and its lifetime: from a job token that dies with the job to a classic token or an App private key that does not expire.
- A deletion commit adds a snapshot without the file; every earlier snapshot still has it.
- A forced push moves a ref, and going private changes who may read from now on; neither removes the commit from clones, forks, cached views or pull request refs.
- The pickaxe shows where a secret entered and left, `git grep` over all commits shows every snapshot that contains it, and `--contains` turns the commit into a list of refs.
- The exposure window starts at the first push, and the only step that works against every copy is revocation at the issuer.

## HOMEWORK

Read sections 21B.8 to 21B.11 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md). Do Exercise 31.1, "Three things that are not removal", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Today you ran the usual repair, saw the search come back clean, and still printed the key from history and from the server. Run those three searches yourself in the lab shell. Next time: secret scanning and push protection, and what they don't cover. Until then, look at the state first and type second. See you in the next one.

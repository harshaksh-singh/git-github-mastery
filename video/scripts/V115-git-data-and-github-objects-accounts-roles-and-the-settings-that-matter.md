# V115: Git data and GitHub objects, accounts, roles, and the settings that matter

- **Part.** 5: GitHub
- **Module.** 19
- **Planned minutes.** 24
- **Prerequisites.** V002, V038, V114
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), sections 15.1 to 15.5
- **Demo scripts.** `labs/ch15/git-vs-github.sh`, `labs/ch15/lab-19-2-inventory.sh`; GitHub-side walkthrough of Lab 19.2

## HOOK

**[ON SCREEN]** "`git clone --mirror` × 40. Monday morning."

A team migrates forty repositories to another host over a weekend with `git clone --mirror` and `git push --mirror`. On Monday the code and the history are intact. The open pull requests, three years of review comments, the release notes, the protection on `main` and the deploy secrets are missing. Nobody exported them, because they were never in Git.

And a second question from the same CTO: a new engineer got Write on one repository. Why can she clone all forty private ones?

Neither question is about a Git command. Both are answered by one habit, and this video builds it. Hold on to the second question. You'll answer it yourself.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair: this is Part 5. For four parts you worked with Git: objects, refs, the index, the working tree. Everything was in a directory you could copy. From here on there's a second system in the picture, GitHub, and the first skill is to keep the two apart.

**[ANIMATION]** stores: id=mirror boxes=GitHub_database:browser,_gh,_API|*Git_repository:on_GitHub|a_clone:clone,_fetch,_push rows=1:B:refs@hl|1:B:objects@hl|2:C:refs@ok|2:C:objects@ok|3:A:pull_requests|4:A:issues,_reviews,_releases@bad|4:A:rules,_roles,_secrets@bad|4:B:refs/pull/*|4:C:refs/pull/*:_mirror_only arrows=2:B>C:Git title=Git_data_or_GitHub_object? at_1=22 at_2=38 at_3=62

**[ANIMATION]** step: 3

The habit: for every thing you touch, know whether it's Git data or a GitHub object. Git data lives in refs and objects, and it travels with `clone`, `fetch` and `push`. Objects are the stored commits and files, and refs are the names that point at them, such as branches and tags. A GitHub object lives in GitHub's database and is reached through the web interface, the GitHub CLI or the API. The best-known one is the pull request, a proposal to merge one branch into another.

**[ANIMATION]** end

A word on how Part 5 is recorded. Local scripts show the Git side of every mechanism, with real output. The GitHub side is a screen walkthrough of a practice repository. The authors captured no GitHub output. The interface changes, so I name each control by its function, and the lab text and the linked documentation are the reference.

**[ANIMATION]** sandbox: steps=outside,room,inside real=the_system_configuration,the_credential_helper inside=system_configuration:_off,no_credential_helper title=Why_GitHub_labs_run_in_your_normal_shell

GitHub-side labs run in your normal shell, not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives.

**[ANIMATION]** end

The demos use `prompt-registry`, a small Python package that stores versioned prompt templates for an LLM application. The same files become your practice repository in Lab 19.1.

The local commands in this video are 🟢 SAFE: `git clone`, `git clone --mirror`, and commands that read.

## LEARNING OBJECTIVES

After this video you can:

- Decide for any item on a repository page whether it is Git data or a GitHub object, and prove it from a clone.
- Say what a mirror clone carries and what it leaves on the platform.
- Distinguish personal accounts, organizations and enterprise accounts.
- Compute a member's effective access from base permission, team roles and direct grants.
- Name the repository settings the section singles out and what each changes.

## CONCEPT

In one sentence: a repository on GitHub is a Git repository, which you can copy completely, surrounded by records in GitHub's database, which you cannot copy with Git at all.

**[ON SCREEN]** The table of section 15.2, built row by row: thing, layer, read it with, arrives with `git clone`?

Git data first. Commits, trees, file contents and annotated tag objects are objects. You read them with `git cat-file -p`, and they arrive with a clone. Branches and tags are refs. You read them with `git for-each-ref` and `git ls-remote`, and branches arrive as remote-tracking branches. Author, committer, message, trailers and signature are inside the commit object.

**[ANIMATION]** walk: id=table columns=thing,layer,read_it_with,arrives_with_git_clone? rows=commits,_trees,_file_contents:objects:git_cat-file_-p:yes|branches_and_tags:refs:git_for-each-ref,_git_ls-remote:yes|.github/_files,_Fixes_#12:Git_data_GitHub_interprets:git_ls-files,_git_log:yes|refs/pull/N/head:refs_GitHub_creates:git_ls-remote:no,_outside_the_default_refspec|pull_requests,_issues,_releases:GitHub_database:browser,_gh,_API:no|roles,_rulesets,_secrets,_settings:GitHub_database:browser,_gh,_API:no marks=1.4:ok,2.4:ok,3.4:ok,4.4:bad,5.4:bad,6.4:bad mono=off title=Git_data_or_GitHub_object? pace=quick

**[ANIMATION]** step: 3

A middle category: Git data that GitHub interprets. `README`, `LICENSE`, and the files under `.github/`, issue forms, templates, `CODEOWNERS`, workflow files, are tracked files. And `Fixes #12` in a message is text in a commit object. To Git it's two words. GitHub reads it.

**[ANIMATION]** step: 4

Git refs that GitHub creates: pull request head refs, `refs/pull/N/head` on the server, read-only. You can list them with `git ls-remote`. They don't arrive with a clone, because they're outside the default refspec, the rule that decides which refs a fetch touches.

**[ANIMATION]** step: 5

GitHub objects, in GitHub's database. A pull request's title, description, reviews, comments, checks and merge state. Issues, sub-issues, labels, milestones, projects, discussions. A release: its title, notes, assets, and its draft, pre-release and latest flags. The tag arrives with a clone, the release doesn't. The "Verified" badge, and which account a commit is attributed to. The fork relationship, stars and watchers.

**[ANIMATION]** step: 6

Roles, teams, rulesets, classic branch protection, secrets, variables, webhooks, deploy keys and settings. None of these arrives with `git clone`.

**[ANIMATION]** end

Three special cases. The wiki is Git, in a second repository with its own URL: a separate clone. Packages, workflow runs, logs, artifacts and caches live in GitHub Packages and GitHub Actions. And with Git LFS, the pointer files are Git and the contents are in LFS storage.

Inside `.git`, a clone holds objects, refs, HEAD, the index, reflogs and `config`. There's no file for an issue or a review. The only traces of the platform are the URL in `remote.origin.url` and what a platform tool wrote into your configuration, such as a credential helper line.

One more boundary rule, flagged in the book as "GitHub, not Git": GitHub also creates Git data on your behalf. Merge commits, squash commits, tags made by a release, the test merge of a pull request. When a commit or ref exists that nobody created with a Git command, ask which platform action wrote it.

Try it now, thirty seconds, on paper. Make two columns, Git data and GitHub object. Sort these four: a branch, an issue, a tag, a release. I'll wait.

**[PAUSE]**

A branch and a tag are refs, so Git data. An issue and a release are GitHub objects. If the release tripped you, that's normal: it points at a tag, and people mix the two up.

**[ANIMATION]** layers: id=accounts layers=personal_account:one_person+owner_plus_collaborators|organization:five_repository_roles+teams+base_permissions+organization_roles|enterprise:owns_organizations+central_policy_and_billing title=Accounts at_1=25 at_2=50 at_3=88

**[ANIMATION]** step: 3

Now accounts. In one sentence: people sign in to user accounts, and organizations and enterprises are containers that own repositories and decide who may do what. A personal account is one person, on GitHub Free or GitHub Pro, with an access model of owner plus collaborators: two levels. Nobody signs in to an organization. Members act through their user accounts, and the organization has five repository roles, teams, base permissions and organization roles. An enterprise owns organizations, with central policy and billing.

**[ANIMATION]** end

The plan decides which features work on private repositories. Public repositories get the full feature set on every plan, which is why the labs use public repositories in a free organization. Organization-level rulesets need the Team plan. A ruleset is a named list of rules for chosen refs. SAML single sign-on, custom roles and internal repositories need Enterprise Cloud.

**[ANIMATION]** layers: id=grants probe=one_member,_one_repository layers=base_permission:every_member,_every_repository|team_roles|a_direct_grant|organization_owner result=the_highest_grant rule=effective_access title=Grants_only_add at_1=55 at_2=68 at_3=78 at_4=86 at_result=30

**[ANIMATION]** step: result

Now roles. In one sentence: in an organization, what a person can do in a repository is the highest of every grant that reaches them: the organization-wide base permission, the roles of their teams, a direct grant, and ownership of the organization.

**[ANIMATION]** layers: id=roles layers=Read:clone+fork+open_issues+comment+submit_a_review|Triage:labels+closing_and_assigning+requesting_reviews|Write:push+merge+approve+code_owner+releases+Actions_secrets|Maintain:configure_merges+push_under_classic_protection|Admin:rulesets+visibility+access+webhooks+deploy_keys+delete title=Five_repository_roles,_each_adds at_1=30 at_2=72 at_5=45

**[ANIMATION]** step: 2

The five repository roles, from least to most: Read, Triage, Write, Maintain, Admin. Read can clone, fork, open issues, comment and submit a review. Triage adds labels, closing and assigning, and requesting reviews.

**[ANIMATION]** step: 3

Write adds pushing, merging a pull request, giving an approval that counts toward required reviews, acting as a code owner, creating releases, and creating Actions secrets and variables.

**[ANIMATION]** step: 5

Maintain adds configuring pull request merges and pushing to branches under classic protection. Admin adds rulesets and branch protection, visibility, access, webhooks and deploy keys, and archive, transfer and delete.

Three rows surprise people. Write can create Actions secrets and edit workflow files, so Write is enough to run code with the repository's secrets. The Maintain role's right to push to protected branches doesn't apply to rulesets, which "have a different bypass model" in the matrix's words. And Read includes submitting a review, although only a review from someone with Write counts toward a requirement.

**[ANIMATION]** step: grants.result

The base permission is a role that every member has on every repository of the organization. The textbook marks the combined "highest wins" rule as an inference from GitHub's pages, not a sentence GitHub publishes. I keep that caveat.

**[ANIMATION]** walk: id=vis columns=change,documented_side_effects rows=public_to_private:stars_and_watchers_erased,_public_forks_stay_public|private_to_public:code,_history_and_Actions_logs_readable,_push_rulesets_disabled|either_direction:no_Git_object_changes marks=3.2:hl mono=off title=Changing_visibility at_1=45 at_3=70

**[ANIMATION]** step: 1

Visibility and settings. Visibility decides who can read a repository at all: public, private, or internal for organizations owned by an enterprise. Changing it has documented side effects. Public to private: stars and watchers are erased, and public forks stay public, detached into a network of their own.

**[ANIMATION]** step: 3

Private to public: everyone can read the code, the complete history, and the Actions history and logs. Push rulesets are disabled. Stars and watchers are erased. Neither direction changes a Git object. Making a repository private doesn't take back what was cloned or forked while it was public.

**[ANIMATION]** end

Then the settings a professional sets on purpose. Each is a GitHub object, none is in a clone, and none is restored by pushing a mirror. The default branch. The features issues, wiki, discussions and projects. Pull request access, which since the thirteenth of February 2026 can be disabled or limited to collaborators. The allowed merge methods. Automatic deletion of head branches. The forking policy. And archive.

## MENTAL MODEL

The textbook's analogy: a manuscript in a publisher's office. You can carry a perfect copy of the manuscript out of the building. The reviewers' notes, the list of who may edit it and the approval stamps belong to the office's filing system.

The analogy breaks in two places. The office edits your manuscript when asked: a merge button creates commits. And the office reads instructions written inside the manuscript: files under `.github/` and words such as `Fixes #12` are Git data that GitHub interprets.

**[ANIMATION]** step: grants.result

For access, the analogy is key cards in an office building. One rule opens some doors for every employee, your department's card opens more, and a card issued to you personally may open one extra room. A door opens if any card you hold opens it. That analogy breaks because buildings have blacklists and GitHub has none: no grant can reduce what another grant gives.

## DIAGRAM

**[DIAGRAM]** The outer box first, then the inner box, then the clone.

```text
  +-------------------------- GitHub ---------------------------------------+
  |  database: issues, pull requests, reviews, releases, labels, stars,     |
  |            roles, teams, rulesets, secrets, webhooks, Actions runs      |
  |                                                                         |
  |   +---------------- Git repository (bare) -----------------+            |
  |   | refs/heads/*   refs/tags/*   refs/pull/*/head          |  <-- reads |
  |   | objects: commits, trees, blobs, tags                   |  .github/, |
  |   +--------------------------------------------------------+  messages  |
  +---------------|------------------------------^--------------------------+
                  | git clone / fetch            | git push
                  v                              |
        +----- your clone -----+          gh, the API, the browser reach the
        | refs + objects + own |          database; Git never does
        | HEAD, index, reflogs |
        +----------------------+
```

The outer box is GitHub. Inside it is a database, and inside it a bare Git repository, one with no working tree. The arrows at the bottom are the only way Git data moves: clone, fetch, push. They touch the inner box only. The arrow on the right is GitHub reading `.github/` and messages out of the Git data.

Quick quiz. Meera joins an organization whose base permission is Read. Her team has Write on one repository. On another, private repository, what can she do: nothing, Read or Write? Say it out loud.

**[PAUSE]**

**[ANIMATION]** walk: id=meera columns=grant,evalkit-service,billing-export_(private) rows=base_permission:Read:Read|team_eval-platform:Write:-|direct_grant:-:-|organization_owner:no:no|effective_access:Write_(highest_wins):Read marks=2.2:hl,5.2:ok,5.3:hl,1.3:hl mono=off title=Meera:_two_repositories pace=quick

**[DIAGRAM]** The second picture, from section 15.4. Meera joins the organization and the team `eval-platform`, which has Write on one repository.

```text
                        repo: evalkit-service        repo: billing-export (private)
  base permission       Read                         Read
  team eval-platform    Write                        -
  direct grant          -                            -
  organization owner    no                           no
                        -----                        -----
  effective access      Write   (highest wins)       Read    <-- "why can she clone it?"
```

Read each column from top to bottom and take the highest. On the right, the only grant is the base permission, and it's Read. That's the answer to the CTO's second question. If you said nothing, you reasoned the way the access was designed.

**[ON SCREEN]** The root-cause box of section 15.4.

```text
Observed behavior : A new engineer with Write on one repository can clone every private repository.
Git state         : Not involved. Her clone works because the server authorized it.
Mechanism         : The organization's base permission is Read. It applies to every member on every
                    repository. Her team's Write grant adds to it on one repository.
Root cause        : Access was designed as "add her to one repository". The base permission that
                    already covered all repositories was never part of the design.
Why GitHub does it: Grants only add. The highest grant wins, and nothing subtracts.
Correct fix       : Decide the base permission on purpose (it can be set to none), and grant
                    repositories through teams. Or make short-term staff outside collaborators,
                    whom base permissions do not reach.
Prevention        : Review the base permission when the organization is created and when people join.
```

Read the line on why GitHub does it: grants only add, the highest grant wins, and nothing subtracts.

## LIVE TERMINAL DEMO

**[TERMINAL]** A bare repository on disk plays the server. It has a default branch, a feature branch whose commit message says `Fixes #12`, and an annotated tag.

```bash
labs/run ch15/git-vs-github
```

```bash
git clone server/practice-repo.git you/practice-repo
cd you/practice-repo
git for-each-ref --format="%(objecttype) %(refname)"
```

How many refs will the clone have, and of which kinds? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch15/git-vs-github/01-clone -->
```text
$ git clone server/practice-repo.git you/practice-repo
Cloning into 'you/practice-repo'...
done.
$ cd you/practice-repo
$ git for-each-ref --format="%(objecttype) %(refname)"
commit refs/heads/main
commit refs/remotes/origin/HEAD
commit refs/remotes/origin/feature/list-names
commit refs/remotes/origin/main
tag refs/tags/v0.1.0
```
<!-- /snippet -->

Five refs, each naming an object. With the objects reachable from them, that is everything the clone received.

```bash
git ls-files .github README.md CONTRIBUTING.md SECURITY.md
```

<!-- snippet: ch15/git-vs-github/02-platform-files -->
```text
# Files that GitHub reads are ordinary tracked files:
$ git ls-files .github README.md CONTRIBUTING.md SECURITY.md
.github/ISSUE_TEMPLATE/1-bug.yml
.github/ISSUE_TEMPLATE/2-feature.yml
.github/ISSUE_TEMPLATE/config.yml
.github/pull_request_template.md
CONTRIBUTING.md
README.md
SECURITY.md
```
<!-- /snippet -->

The files that configure the platform came along because they are tracked files.

```bash
git log -1 --format=%B origin/feature/list-names
git log --all --oneline --grep="#12"
```

<!-- snippet: ch15/git-vs-github/03-message -->
```text
$ git log -1 --format=%B origin/feature/list-names
Add names() to list registered prompts

Fixes #12

$ git log --all --oneline --grep="#12"
c130f61 Add names() to list registered prompts
```
<!-- /snippet -->

To Git, `Fixes #12` is two words in a message. No issue 12 exists in this sandbox.

```bash
cd ../..
git clone --mirror server/practice-repo.git backup/practice-repo.git
git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
```

A mirror asks for every ref the server offers. What does it receive beyond refs and objects? Make your prediction.

**[PAUSE]**

<!-- snippet: ch15/git-vs-github/04-mirror -->
```text
$ cd ../..
$ git clone --mirror server/practice-repo.git backup/practice-repo.git
Cloning into bare repository 'backup/practice-repo.git'...
done.
$ git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
commit refs/heads/feature/list-names
commit refs/heads/main
tag refs/tags/v0.1.0
$ git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
33
```
<!-- /snippet -->

**[ANIMATION]** step: mirror.4

Nothing. Three refs, 33 objects. Against GitHub a mirror also receives the `refs/pull/*` refs, and no issue, review, release or setting. That's Monday morning from the hook.

**[TERMINAL]** The replay of Lab 19.2, Part A, shows the other direction: what your clone has that the server never had.

```bash
labs/run ch15/lab-19-2-inventory
```

<!-- snippet: ch15/lab-19-2-inventory/04-local-only -->
```text
# Things in your .git that the server never had and no clone receives:
$ git config list --local --name-only
core.repositoryformatversion
core.filemode
core.bare
core.logallrefupdates
core.ignorecase
core.precomposeunicode
remote.origin.url
remote.origin.fetch
branch.main.remote
branch.main.merge
$ git reflog -2
bf7889c HEAD@{0}: clone: from $LAB/ch15/lab-19-2-inventory/server/practice-repo.git
```
<!-- /snippet -->

Your local configuration and your reflog. No clone receives them.

**[ON SCREEN]** GitHub walkthrough, Lab 19.2 Part B, in the normal shell. The interface changes; the lab text and the documentation are the reference. No output is shown.

Open your practice repository's page in the browser and walk it from top to bottom. For each element, say the column. The file list and the README: Git data. The branch selector and the tag count: refs. The commit count: objects. The star and watch counters: database. The issue and pull request tabs: database. The "About" description and topics: settings. The releases panel: a GitHub object pointing at a tag.

Then prove it from the terminal with the commands of the lab.

```bash
cd ~/git-mastery/practice-repo
git ls-remote origin
gh repo view --json nameWithOwner,visibility,isFork,parent,stargazerCount,watchers,defaultBranchRef
gh issue list
gh label list
gh release list
gh ruleset list
gh secret list
```

The rule you're demonstrating: what `git ls-remote` can show is Git data, and what only `gh` can show is a GitHub object. The lab also has you create one test issue with `gh issue create`. Do that in your own repository when you do the lab.

## COMMON MISTAKES

Five mistakes to watch for.

1. Treating `git clone --mirror` as a backup of the repository page. Root cause: a mirror receives refs and objects; issues, reviews, releases, rules, roles and secrets are not Git data.
2. Granting Write on one repository and assuming the person sees nothing else. Root cause: the base permission applies to every member on every repository, and the highest grant wins.
3. Giving Write to someone who must not reach secrets. Root cause: Write can edit workflow files and create Actions secrets, so it is enough to run code with the repository's secrets.
4. Making a repository private to take back a leak. Root cause: visibility changes no Git object and does not recall what was cloned or forked.
5. Expecting settings to return after pushing a mirror to a new repository. Root cause: every setting is a GitHub object.

## PRODUCTION EXAMPLE

Now, out of the lab. A startup's code lives under the founder's personal account, with ten collaborators. Every collaborator can push to everything they were added to, there are no teams, and the company's access model is one person's account. The fix is to move to an organization. Transferring a repository keeps its Git data, issues, pull requests, wiki, stars and watchers, and its webhooks, secrets and deploy keys stay attached. What the company gains is the access model of this video: a base permission chosen on purpose, and repositories granted through teams.

One warning from the same section for the day someone leaves: deploy keys are outside this model. A deploy key is an SSH key attached to one repository, not to a person. Anyone holding a deploy key's private half can use it, in the words of GitHub's roles page, "even if they're later removed from the organization". Offboarding a person doesn't offboard the credentials they created.

## PRACTICE EXERCISE

Your turn. Do Lab 19.2, "An inventory of Git data and GitHub objects", in [`lab-manual/m19-github-platform.md`](../../lab-manual/m19-github-platform.md). The lab gives you a table of twelve things. Fill in the layer and the mirror column for every row on paper before you run a single command. Then find the command that proves each row.

The challenge is Exercise 19.3, "Effective access", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 219 of the CTO question bank:

> "Take ten things on a repository's page on GitHub. For each, is it Git data or a GitHub object, and how do you prove it from a terminal?"

**[PAUSE]**

**[ANIMATION]** step: table.6

Answer out loud. A strong answer picks items from every region of the page, includes at least one from the middle category of Git data that the platform interprets, and gives for each a command, not an opinion. It states the test that separates the two columns and mentions what GitHub writes into Git on your behalf.

## RECAP

Let's land this.

You should now be able to say:

- Git data is refs and objects and travels with clone, fetch and push; GitHub objects live in a database and are reached with the browser, `gh` or the API.
- A mirror carries refs and objects, and nothing else.
- Files under `.github/` and closing keywords are Git data that GitHub interprets.
- Effective access is the highest of base permission, team grants, direct grants and ownership; nothing subtracts.
- Visibility and settings are GitHub objects and change no Git object.

## HOMEWORK

Read sections 15.1 to 15.5 of [Chapter 15](../../textbook/ch15-github.md). Do Exercise 19.1, "Git data or GitHub object?", and Exercise 19.2, "Settings on purpose", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Return to the five-item list from video 2 and prove each entry.

**[ANIMATION]** step: mirror.4

Today you sorted a repository page into two columns, and you can prove each row from a terminal. Practise it on one real repository this week. Next time: forks and the fork network. Until then, look at the state first and type second. See you in the next one.

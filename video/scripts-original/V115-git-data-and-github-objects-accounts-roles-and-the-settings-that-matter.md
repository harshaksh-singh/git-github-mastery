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

Neither question is about a Git command. Both are answered by one habit, and this video builds it.

## INTRODUCTION

Welcome to Part 5. For four parts you worked with Git: objects, refs, the index, the working tree. Everything was in a directory you could copy. From here on there is a second system in the picture, GitHub, and the first skill is to keep the two apart.

The habit: for every thing you touch, know whether it is Git data, which lives in refs and objects and travels with `clone`, `fetch` and `push`, or a GitHub object, which lives in GitHub's database and is reached through the web interface, the GitHub CLI or the API.

A word on how Part 5 is recorded. Local scripts show the Git side of every mechanism, with real output. The GitHub side is a screen walkthrough of a practice repository. The authors captured no GitHub output. The interface changes, so I name each control by its function, and the lab text and the linked documentation are the reference. GitHub-side labs run in your normal shell, not in `labs/shell`, because the lab shell switches off the system configuration where the credential helper lives.

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

Git data. Commits, trees, file contents and annotated tag objects are objects; you read them with `git cat-file -p`, and they arrive with a clone. Branches and tags are refs; you read them with `git for-each-ref` and `git ls-remote`; branches arrive as remote-tracking branches. Author, committer, message, trailers and signature are inside the commit object.

A middle category: Git data that GitHub interprets. `README`, `LICENSE`, and the files under `.github/`, issue forms, templates, `CODEOWNERS`, workflow files, are tracked files. And `Fixes #12` in a message is text in a commit object. To Git it is two words. GitHub reads it.

Git refs that GitHub creates: pull request head refs, `refs/pull/N/head` on the server, read-only. You can list them with `git ls-remote`. They do not arrive with a clone, because they are outside the default refspec.

GitHub objects, in GitHub's database. A pull request's title, description, reviews, comments, checks and merge state. Issues, sub-issues, labels, milestones, projects, discussions. A release: its title, notes, assets, and its draft, pre-release and latest flags; the tag arrives with a clone, the release does not. The "Verified" badge, and which account a commit is attributed to. The fork relationship, stars and watchers. Roles, teams, rulesets, classic branch protection, secrets, variables, webhooks, deploy keys and settings. None of these arrives with `git clone`.

Three special cases. The wiki is Git, in a second repository with its own URL: a separate clone. Packages, workflow runs, logs, artifacts and caches live in GitHub Packages and GitHub Actions. And with Git LFS, the pointer files are Git and the contents are in LFS storage.

Inside `.git`, a clone holds objects, refs, HEAD, the index, reflogs and `config`. There is no file for an issue or a review. The only traces of the platform are the URL in `remote.origin.url` and what a platform tool wrote into your configuration, such as a credential helper line.

One more boundary rule, flagged in the book as "GitHub, not Git": GitHub also creates Git data on your behalf. Merge commits, squash commits, tags made by a release, the test merge of a pull request. When a commit or ref exists that nobody created with a Git command, ask which platform action wrote it.

Accounts. In one sentence: people sign in to user accounts; organizations and enterprises are containers that own repositories and decide who may do what. A personal account is one person, on GitHub Free or GitHub Pro, with an access model of owner plus collaborators: two levels. Nobody signs in to an organization; members act through their user accounts, and the organization has five repository roles, teams, base permissions and organization roles. An enterprise owns organizations, with central policy and billing.

The plan decides which features work on private repositories. Public repositories get the full feature set on every plan, which is why the labs use public repositories in a free organization. Organization-level rulesets need the Team plan; SAML single sign-on, custom roles and internal repositories need Enterprise Cloud.

Roles. In one sentence: in an organization, what a person can do in a repository is the highest of every grant that reaches them: the organization-wide base permission, the roles of their teams, a direct grant, and ownership of the organization.

The five repository roles, from least to most: Read, Triage, Write, Maintain, Admin. Read can clone, fork, open issues, comment and submit a review. Triage adds labels, closing and assigning, and requesting reviews. Write adds pushing, merging a pull request, giving an approval that counts toward required reviews, acting as a code owner, creating releases, and creating Actions secrets and variables. Maintain adds configuring pull request merges and pushing to branches under classic protection. Admin adds rulesets and branch protection, visibility, access, webhooks and deploy keys, and archive, transfer and delete.

Three rows surprise people. Write can create Actions secrets and edit workflow files, so Write is enough to run code with the repository's secrets. The Maintain role's right to push to protected branches does not apply to rulesets, which "have a different bypass model" in the matrix's words. And Read includes submitting a review, although only a review from someone with Write counts toward a requirement.

The base permission is a role that every member has on every repository of the organization. The textbook marks the combined "highest wins" rule as an inference from GitHub's pages, not a sentence GitHub publishes; I keep that caveat.

Visibility and settings. Visibility decides who can read a repository at all: public, private, or internal for organizations owned by an enterprise. Changing it has documented side effects. Public to private: stars and watchers are erased, and public forks stay public, detached into a network of their own. Private to public: everyone can read the code, the complete history, and the Actions history and logs; push rulesets are disabled; stars and watchers are erased. Neither direction changes a Git object. Making a repository private does not take back what was cloned or forked while it was public.

The settings a professional sets on purpose, each a GitHub object, none in a clone, none restored by pushing a mirror: the default branch; the features issues, wiki, discussions and projects; pull request access, which since 13 February 2026 can be disabled or limited to collaborators; the allowed merge methods; automatic deletion of head branches; the forking policy; and archive.

## MENTAL MODEL

The textbook's analogy: a manuscript in a publisher's office. You can carry a perfect copy of the manuscript out of the building. The reviewers' notes, the list of who may edit it and the approval stamps belong to the office's filing system.

The analogy breaks in two places. The office edits your manuscript when asked: a merge button creates commits. And the office reads instructions written inside the manuscript: files under `.github/` and words such as `Fixes #12` are Git data that GitHub interprets.

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

The outer box is GitHub. Inside it is a database, and inside it a bare Git repository. The arrows at the bottom are the only way Git data moves: clone, fetch, push. They touch the inner box only. The arrow on the right is GitHub reading `.github/` and messages out of the Git data.

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

Read each column from top to bottom and take the highest. On the right, the only grant is the base permission, and it is Read. That is the answer to the CTO's second question.

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

**[PAUSE]** How many refs will the clone have, and of which kinds?

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

**[PAUSE]** A mirror asks for every ref the server offers. What does it receive beyond refs and objects?

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

Nothing. Three refs, 33 objects. Against GitHub a mirror also receives the `refs/pull/*` refs, and no issue, review, release or setting.

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

The rule you are demonstrating: what `git ls-remote` can show is Git data; what only `gh` can show is a GitHub object. The lab also has you create one test issue with `gh issue create`; do that in your own repository when you do the lab.

## COMMON MISTAKES

1. Treating `git clone --mirror` as a backup of the repository page. Root cause: a mirror receives refs and objects; issues, reviews, releases, rules, roles and secrets are not Git data.
2. Granting Write on one repository and assuming the person sees nothing else. Root cause: the base permission applies to every member on every repository, and the highest grant wins.
3. Giving Write to someone who must not reach secrets. Root cause: Write can edit workflow files and create Actions secrets, so it is enough to run code with the repository's secrets.
4. Making a repository private to take back a leak. Root cause: visibility changes no Git object and does not recall what was cloned or forked.
5. Expecting settings to return after pushing a mirror to a new repository. Root cause: every setting is a GitHub object.

## PRODUCTION EXAMPLE

A startup's code lives under the founder's personal account, with ten collaborators. Every collaborator can push to everything they were added to, there are no teams, and the company's access model is one person's account. The fix is to move to an organization. Transferring a repository keeps its Git data, issues, pull requests, wiki, stars and watchers, and its webhooks, secrets and deploy keys stay attached. What the company gains is the access model of this video: a base permission chosen on purpose, and repositories granted through teams.

One warning from the same section for the day someone leaves: deploy keys are outside this model. Anyone holding a deploy key's private half can use it, in the words of GitHub's roles page, "even if they're later removed from the organization". Offboarding a person does not offboard the credentials they created.

## PRACTICE EXERCISE

Do Lab 19.2, "An inventory of Git data and GitHub objects", in [`lab-manual/m19-github-platform.md`](../../lab-manual/m19-github-platform.md). The lab gives you a table of twelve things. Fill in the layer and the mirror column for every row on paper before you run a single command. Then find the command that proves each row.

The challenge is Exercise 19.3, "Effective access", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 219 of the CTO question bank:

> "Take ten things on a repository's page on GitHub. For each, is it Git data or a GitHub object, and how do you prove it from a terminal?"

A strong answer picks items from every region of the page, includes at least one from the middle category of Git data that the platform interprets, and gives for each a command, not an opinion. It states the test that separates the two columns and mentions what GitHub writes into Git on your behalf.

## RECAP

You should now be able to say:

- Git data is refs and objects and travels with clone, fetch and push; GitHub objects live in a database and are reached with the browser, `gh` or the API.
- A mirror carries refs and objects, and nothing else.
- Files under `.github/` and closing keywords are Git data that GitHub interprets.
- Effective access is the highest of base permission, team grants, direct grants and ownership; nothing subtracts.
- Visibility and settings are GitHub objects and change no Git object.

## HOMEWORK

Read sections 15.1 to 15.5 of [Chapter 15](../../textbook/ch15-github.md). Do Exercise 19.1, "Git data or GitHub object?", and Exercise 19.2, "Settings on purpose", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Return to the five-item list from V002 and prove each entry.

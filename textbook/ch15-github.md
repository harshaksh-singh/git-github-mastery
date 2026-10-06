# Chapter 15: GitHub

> **Baseline.** Git 2.55.0 on macOS; GitHub CLI 2.88.1; GitHub facts as of 1 October 2026, re-read on docs.github.com on 2 October 2026 where a link is given. Transcripts are real output from `labs/ch15/`. Nothing in this chapter was run against GitHub: where the text says what GitHub shows or does, it is described from the linked documentation, and the interface it describes changes on a scale of months.

## 15.1 Why this matters

Four questions a CTO can ask, none of which is about a Git command:

1. "The intern pushed a staging key to her fork. We deleted the fork within the hour. Is the key gone?"
2. "The release page says v0.3.0. The build machine runs `git describe` and prints v0.2.0-1. Which one is the version?"
3. "A new engineer got Write on one repository. Why can she clone all forty private ones?"
4. "We may move to another host next year. What does `git clone --mirror` take with it, and what stays behind?"

The answers: no, and the commit is reachable through your own repository's URL (section 15.7). Both are, because a release and a tag are different objects made by different programs (section 15.12). Because access is the highest of several grants, and one of them applies to every member (section 15.4). And the mirror takes refs and objects; issues, reviews, releases, rules, roles and secrets stay behind, because none of them is Git data (section 15.2).

All four answers come from one habit: for every thing you touch, know whether it is **Git data**, which lives in refs and objects and travels with `clone`, `fetch` and `push`, or a **GitHub object**, which lives in GitHub's database and is reached through the web interface, the GitHub CLI or the API. This chapter builds that map, then walks the platform with it. Authentication ([Chapter 16](ch16-authentication.md)), pull requests ([Chapter 17](ch17-pull-requests.md)), rulesets ([Chapter 18](ch18-branch-protection.md)), CODEOWNERS ([Chapter 19](ch19-codeowners.md)), Actions ([Chapter 20A](ch20a-actions-fundamentals.md)) and security ([Chapter 21B](ch21b-repository-security-incident-response.md)) have their own chapters and are only pointed to here.

The demos use `prompt-registry`, a small Python package that stores versioned prompt templates for an LLM application. The same files become your practice repository in Lab 19.1.

## 15.2 Git data and GitHub objects

**In one sentence.** A repository on GitHub is a Git repository, which you can copy completely, surrounded by records in GitHub's database, which you cannot copy with Git at all.

**Analogy.** A manuscript in a publisher's office. You can carry a perfect copy of the manuscript out of the building. The reviewers' notes, the list of who may edit it and the approval stamps belong to the office's filing system. The analogy breaks in two places. The office edits your manuscript when asked: a merge button creates commits. And the office reads instructions written inside the manuscript: files under `.github/` and words such as `Fixes #12` are Git data that GitHub interprets.

**Precisely.** Chapter 1 gave a first version of this table. This one adds the command that reads each thing. The GitHub rows are from the Phase 0 report, sections 2 and 12.

| Thing | Layer | Where it lives | Read it with | Arrives with `git clone`? |
|---|---|---|---|---|
| Commits, trees, file contents, annotated tag objects | Git | objects | `git cat-file -p` | yes |
| Branches and tags | Git | refs | `git for-each-ref`, `git ls-remote` | yes; branches as remote-tracking branches |
| Author, committer, message, trailers, signature | Git | inside the commit object | `git log --format=fuller`, `git cat-file -p` | yes |
| `README`, `LICENSE`, `.github/` (issue forms, templates, `CODEOWNERS`, workflow files) | Git data that GitHub interprets | tracked files | `git ls-files` | yes |
| `Fixes #12` in a message or description | text that GitHub interprets | commit object, or the pull request description | `git log --grep` | the commit yes |
| Pull request head refs | Git refs that GitHub creates | `refs/pull/N/head` on the server, read-only | `git ls-remote origin 'refs/pull/*'` | no: outside the default refspec ([Chapter 17](ch17-pull-requests.md)) |
| Pull request: title, description, reviews, comments, checks, merge state | GitHub | database | `gh pr view`, `gh api` | no |
| Issue, sub-issue, label, milestone, project, discussion | GitHub | database | `gh issue`, `gh label`, `gh project`, `gh api` | no |
| Release: title, notes, assets, draft, pre-release and latest flags | GitHub | database; points at a tag | `gh release view` | the tag yes, the release no |
| The "Verified" badge; which account a commit is attributed to | GitHub | database | web, `gh api` | no ([Chapter 21B](ch21b-repository-security-incident-response.md)) |
| Fork relationship, stars, watchers | GitHub | database | `gh repo view --json parent,stargazerCount` | no |
| Roles, teams, rulesets, classic branch protection, secrets, variables, webhooks, deploy keys, settings | GitHub | repository and organization settings | `gh api`, `gh ruleset`, `gh secret list` | no |
| Wiki | Git, in a second repository | `OWNER/REPO.wiki.git` | `git clone` of that URL ([wikis](https://docs.github.com/en/communities/documenting-your-project-with-wikis/adding-or-editing-wiki-pages)) | no: a separate clone |
| Packages and images; workflow runs, logs, artifacts, caches | GitHub Packages; GitHub Actions | GitHub | the package manager; `gh run`, `gh cache` | no |
| Large files tracked with Git LFS | pointer files are Git; contents are in LFS storage | [Chapter 22](ch22-git-lfs.md) | `git lfs` | pointers yes |

**Inside `.git`.** A clone holds objects, refs, `HEAD`, the index, reflogs and `config` ([Chapter 3](ch03-git-internals.md)). There is no file for an issue or a review. The only traces of the platform are the URL in `remote.origin.url` and what a platform tool wrote into your configuration, such as a credential helper line ([Chapter 16](ch16-authentication.md)).

**See it.** A bare repository on disk plays the server. It has a default branch, a feature branch whose commit message says `Fixes #12`, and an annotated tag.

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

Five refs, each naming an object: with the objects reachable from them, that is everything the clone received. The files that configure the platform came along because they are tracked files:

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

<!-- snippet: ch15/git-vs-github/03-message -->
```text
$ git log -1 --format=%B origin/feature/list-names
Add names() to list registered prompts

Fixes #12

$ git log --all --oneline --grep="#12"
c130f61 Add names() to list registered prompts
```
<!-- /snippet -->

To Git, `Fixes #12` is two words in a message; no issue 12 exists in this sandbox. On GitHub the same text links the commit to an issue and can close it (section 15.8).

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

A mirror clone asks for every ref the server offers ([Chapter 12](ch12-remote-operations.md), section 12.3) and still receives only refs and objects: three refs, 33 objects. Against GitHub it also receives the `refs/pull/*` refs, and no issue, review, release or setting.

**Picture.**

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

**In production.** A team migrates forty repositories to another host over a weekend with `git clone --mirror` and `git push --mirror`. On Monday the code and history are intact. The open pull requests, three years of review comments, the release notes, the protection on `main` and the deploy secrets are missing. Nobody exported them, because they were never in Git. Lab 19.2 builds the inventory that such a plan starts from.

> **GitHub, not Git.** GitHub also creates Git data on your behalf: merge commits, squash commits, tags made by a release, the test merge of a pull request. When a commit or ref exists that nobody created with a Git command, ask which platform action wrote it.

## 15.3 Accounts: personal, organization, enterprise

**In one sentence.** People sign in to user accounts; organizations and enterprises are containers that own repositories and decide who may do what.

**Precisely.** GitHub has three account types ([types of accounts](https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts)).

| Account | Who signs in | Owns | Plans | Access model |
|---|---|---|---|---|
| Personal (a user account) | one person | repositories, packages, projects | GitHub Free or GitHub Pro | owner plus collaborators: two levels ([personal repositories](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository)) |
| Organization | nobody: members act through their user accounts | repositories, packages, projects, teams | Free, Team, Enterprise Cloud | five repository roles, teams, base permissions, organization roles |
| Enterprise | nobody | organizations | GitHub Enterprise | central policy and billing over several organizations |

A machine user is a user account that automation signs in with. A managed user account is created by an enterprise through its identity provider and cannot contribute outside that enterprise. Converting a personal account into an organization was deprecated on 12 January 2026 in favor of moving work to an organization ([changelog](https://github.blog/changelog/2026-01-12-deprecation-of-user-to-organization-account-transformation/)).

The plan decides which features work on **private** repositories. Public repositories get the full feature set on every plan, which is why the labs use public repositories in a free organization (report, section 2). Organization-level rulesets need the Team plan; SAML single sign-on, custom roles and internal repositories need Enterprise Cloud ([plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans)).

**In production.** A startup's code lives under the founder's personal account, with ten collaborators. Every collaborator can push to everything they were added to, there are no teams, and the company's access model is one person's account. Transferring a repository to an organization keeps its Git data, issues, pull requests, wiki, stars and watchers, and its webhooks, secrets and deploy keys stay attached ([transferring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository)); what you gain is the access model of the next section.

## 15.4 Who can do what: members, teams, roles and effective access

**In one sentence.** In an organization, what a person can do in a repository is the highest of every grant that reaches them: the organization-wide base permission, the roles of their teams, a direct grant, and ownership of the organization.

**Analogy.** Key cards in an office building. One rule opens some doors for every employee, your department's card opens more, and a card issued to you personally may open one extra room. A door opens if any card you hold opens it. The analogy breaks because buildings have blacklists and GitHub has none: no grant can reduce what another grant gives.

**Precisely.** The people:

- A **member** belongs to the organization. An **owner** is a member with complete administrative access; GitHub advises at least two ([organization roles](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/roles-in-an-organization)). Owners have admin access to every repository of the organization.
- A **team** is a group of members. Teams can be nested, and a child team inherits the parent's access. Outside collaborators cannot be on a team ([teams](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)).
- An **outside collaborator** is not a member and has access to one or more repositories through direct grants only. Base permissions do not apply to them ([base permissions](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization)).

The five repository roles, from least to most access, with the rows of GitHub's permission matrix that decide most arguments ([repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization#permissions-for-each-role)):

| Action | Read | Triage | Write | Maintain | Admin |
|---|---|---|---|---|---|
| Clone, fork, open issues, comment, submit a review | yes | yes | yes | yes | yes |
| Apply labels, close and assign any issue or pull request, request reviews | no | yes | yes | yes | yes |
| Push, merge a pull request, create labels and milestones | no | no | yes | yes | yes |
| Give an approval that counts toward required reviews; act as a code owner | no | no | yes | yes | yes |
| Create and edit releases; create and edit Actions secrets and variables | no | no | yes | yes | yes |
| Configure pull request merges, edit the description, manage topics | no | no | no | yes | yes |
| Push to protected branches (classic protection only) | no | no | no | yes | yes |
| Manage rulesets and branch protection; change visibility; manage access, webhooks and deploy keys; rename the default branch; archive, transfer, delete | no | no | no | no | yes |

Three rows surprise people. Write can create Actions secrets and edit workflow files, so Write is enough to run code with the repository's secrets ([Chapter 21A](ch21a-actions-security.md)). The Maintain role's right to push to protected branches does not apply to rulesets, which "have a different bypass model" in the matrix's words ([Chapter 18](ch18-branch-protection.md)). And Read includes submitting a review, although only a review from someone with Write counts toward a requirement.

The **base permission** is a role that every member has on every repository of the organization; a higher grant on a repository overrides it. GitHub's page states the default as Read on the organization's public repositories. Custom repository roles, up to 20, exist only on Enterprise Cloud ([custom roles](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/about-custom-repository-roles)).

**Effective access** is the highest of the base permission, team grants (including those inherited from parent teams), direct grants, and admin through organization ownership; an outside collaborator has direct grants only. The report marks this combined rule as an inference from the pages above, not a sentence GitHub publishes.

**Picture.** Meera joins the organization and the team `eval-platform`, which has Write on one repository.

```text
                        repo: evalkit-service        repo: billing-export (private)
  base permission       Read                         Read
  team eval-platform    Write                        -
  direct grant          -                            -
  organization owner    no                           no
                        -----                        -----
  effective access      Write   (highest wins)       Read    <-- "why can she clone it?"
```

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

**In production.** Deploy keys are outside this model. GitHub's roles page warns that anyone holding a deploy key's private half can use it "even if they're later removed from the organization". Offboarding a person does not offboard the credentials they created ([Chapter 16](ch16-authentication.md)).

## 15.5 Visibility, and the repository settings that matter

**In one sentence.** Visibility decides who can read a repository at all; the settings decide which platform features exist in it and how pull requests land.

**Precisely.** A repository is **public** (readable by everyone on the internet) or **private** (readable by the owner, people granted access and, in an organization, members according to their grants). Organizations owned by an enterprise can also create **internal** repositories, readable by all enterprise members ([about repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility)). Organization owners can read every repository of the organization, whatever its visibility.

Changing visibility is an Admin action with documented side effects ([setting repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)):

| Change | What also happens |
|---|---|
| public to private | Stars and watchers are erased. Public forks stay public, detached into a network of their own. On a Free plan some features stop working, and code scanning stops unless licensed for private repositories. |
| private to public | Everyone can read the code, the complete history, and the Actions history and logs. Anyone can fork. Push rulesets are disabled. Private forks stay private, detached. Stars and watchers are erased. |

Neither direction changes a Git object. Making a repository private does not take back what was cloned or forked while it was public, and making it public publishes every commit that any ref reaches, including the old one that contained a password ([Chapter 21B](ch21b-repository-security-incident-response.md)).

The settings a professional sets on purpose. Each is a GitHub object, so none of them is in a clone, and none of them is restored by pushing a mirror:

| Setting | What it does | Why it matters | Check or set |
|---|---|---|---|
| Default branch | what clones check out, pull requests target and closing keywords act on | clones keep the old name after a rename ([Chapter 12](ch12-remote-operations.md), section 12.3) | `gh repo view --json defaultBranchRef`; `gh repo edit --default-branch` |
| Features: issues, wiki, discussions, projects | shows or hides each tab | an unused feature is a place where questions go unanswered | `gh repo edit --enable-wiki=false` and siblings |
| Pull request access | since 13 February 2026 pull requests can be disabled, or creation limited to collaborators ([changelog](https://github.blog/changelog/2026-02-13-new-repository-settings-for-configuring-pull-request-access/)) | mirrors and read-only code | web interface |
| Allowed merge methods | which of merge commit, squash and rebase the merge button offers | decides the shape of history on the default branch ([Chapter 17](ch17-pull-requests.md)) | `gh repo edit --enable-squash-merge` and siblings |
| Automatically delete head branches | deletes a pull request's branch after merging ([docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches)) | your clone still needs `git fetch --prune` | `gh repo edit --delete-branch-on-merge` |
| Forking policy | whether a private organization repository may be forked | a fork of a private repository is a second copy under someone else's control | `gh repo edit --allow-forking` |
| Archive | makes issues, pull requests, code, releases and settings read-only ([docs](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories)) | the honest state for code nobody maintains | `gh repo archive` |

The flags were checked against `gh repo edit --help` of gh 2.88.1. `gh repo edit --visibility` also needs `--accept-visibility-change-consequences`.

**In production.** With automatic deletion enabled, an author's `git branch -vv` shows twenty branches marked `gone` after a month. The setting deleted refs on the server. Remote-tracking refs go when you prune, and local branches when you delete them ([Chapter 12](ch12-remote-operations.md), section 12.11): one setting, three kinds of ref, three owners.

## 15.6 Stars and watchers

A **star** is a bookmark and a public signal. It makes a repository appear on your stars page and feeds rankings: "many of GitHub's repository rankings depend on the number of stars", says GitHub's page, and anyone can list the stargazers of a repository they can read by appending `/stargazers` to its URL ([stars](https://docs.github.com/en/get-started/exploring-projects-on-github/saving-repositories-with-stars)).

**Watching** is a notification subscription. When you watch a repository you are subscribed to its activity; you can narrow that to chosen event types (issues, pull requests, releases, security alerts, discussions) or ignore the repository. By default you automatically watch repositories you create, and repositories you are given push access to, except forks. An account can watch at most 10,000 repositories ([configuring notifications](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/configuring-notifications), [about notifications](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/about-notifications)).

Neither is evidence of quality. Stars can be manufactured: the Phase 0 report cites a network of more than 3,000 accounts that distributed malware through repositories made to look popular ([Check Point](https://research.checkpoint.com/2024/stargazers-ghost-network/)), and a star count says nothing about who controls a repository today. [Chapter 21B](ch21b-repository-security-incident-response.md) covers the attack. A useful subscription is narrow: releases and security alerts of the dependencies you ship.

## 15.7 Forks and the fork network

**In one sentence.** A fork is a second repository on GitHub with its own refs, settings and permissions, connected to the repository it was made from, and storing its Git data together with it.

**Analogy.** A branch office that keeps its own ledger and uses head office's warehouse. Each office has its own list of goods (its refs). The goods (the objects) are in one building, and anyone who knows a crate's serial number can ask either office for it. The analogy breaks when an office closes: its list is gone and the crates remain.

**Precisely.** From the forks reference ([forks](https://docs.github.com/en/pull-requests/reference/forks)):

- A fork has its own branches, tags, issues, pull requests, Actions, labels and wiki, and its own permissions. Forks of public repositories are public and forks of private repositories are private; a fork's visibility cannot be changed by itself.
- A repository network is the upstream repository, its forks, and forks of those forks. "Repositories in the network share Git data." Commits pushed to any repository in a network "can be accessible from other repositories in that network, including the upstream repository", and this holds "even after a fork is deleted". Owners of an upstream repository can read all forks in the network.
- Deleting a private repository deletes its private forks. Deleting a public repository makes an active public fork the new upstream. Removing a person's access to a private repository deletes their forks of it.
- Branch and tag rulesets are not inherited by forks; push rulesets apply to the whole network ([Chapter 18](ch18-branch-protection.md)).
- A deleted repository can be restored within 90 days, unless its fork network is not empty ([restoring a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/restoring-a-deleted-repository)).

**Inside `.git`.** To your clone a fork is one more remote ([Chapter 12](ch12-remote-operations.md), section 12.10). The parent-and-fork relationship is a GitHub object that no ref or configuration key records. The `upstream` remote that `gh repo fork` and `gh repo clone` add is a convenience in `.git/config`, not the relationship.

**See it.** GitHub documents the behavior and not the mechanism. Git has a documented mechanism of its own with the same property: **namespaces**, which divide the refs of one repository into several sets that are served as separate repositories "while sharing the object store" ([gitnamespaces](https://git-scm.com/docs/gitnamespaces)). The demo uses it as a model. It is not a claim about how GitHub is built.

<!-- snippet: ch15/fork-network/01-upstream -->
```text
# The platform: one object database. The upstream repository acme-ml/prompt-registry is a namespace in it.
$ git init -q --bare platform/network.git
$ GIT_NAMESPACE=acme-ml git -C seed push -q ../platform/network.git main
$ git -C platform/network.git for-each-ref --format="%(refname)"
refs/namespaces/acme-ml/refs/heads/main
$ find platform/network.git/objects -type f | wc -l | tr -d ' '
27
```
<!-- /snippet -->

<!-- snippet: ch15/fork-network/02-fork -->
```text
# Forking: the platform writes a ref for the fork. No object is copied.
$ git -C platform/network.git update-ref refs/namespaces/you/refs/heads/main refs/namespaces/acme-ml/refs/heads/main
$ git -C platform/network.git for-each-ref --format="%(refname)"
refs/namespaces/acme-ml/refs/heads/main
refs/namespaces/you/refs/heads/main
$ find platform/network.git/objects -type f | wc -l | tr -d ' '
27
```
<!-- /snippet -->

Forking wrote one ref. The object count did not move: 27 before, 27 after.

<!-- snippet: ch15/fork-network/03-clone-fork -->
```text
$ GIT_NAMESPACE=you git clone -q platform/network.git you/prompt-registry
$ cd you/prompt-registry
$ git branch -a
* main
  remotes/origin/main
```
<!-- /snippet -->

<!-- snippet: ch15/fork-network/04-push-to-fork -->
```text
$ git switch -q -c debug/staging-config
$ printf 'STAGING_API_KEY=FAKE-KEY-for-the-lab\n' > staging.env
$ git add -f staging.env && git commit -q -m "Add staging config for debugging"
$ GIT_NAMESPACE=you git push -q origin debug/staging-config
$ git rev-parse HEAD
915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
$ cd ../..
$ find platform/network.git/objects -type f | wc -l | tr -d ' '
30
```
<!-- /snippet -->

You pushed a commit with a staging key to a branch of your fork. Three new objects went into the one object database. Each repository still lists only its own refs:

<!-- snippet: ch15/fork-network/05-two-views -->
```text
# What each repository lists:
$ GIT_NAMESPACE=acme-ml git ls-remote platform/network.git
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/heads/main
$ GIT_NAMESPACE=you git ls-remote platform/network.git
915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5	refs/heads/debug/staging-config
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/heads/main
```
<!-- /snippet -->

The upstream does not list the branch. Now a visitor who knows nothing but the upstream repository and the commit ID `915a81e`:

<!-- snippet: ch15/fork-network/06-by-id-through-upstream -->
```text
# A visitor who only knows the upstream repository, and the commit ID:
$ GIT_NAMESPACE=acme-ml git clone -q platform/network.git visitor/prompt-registry
$ cd visitor/prompt-registry
$ GIT_NAMESPACE=acme-ml git fetch origin 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
From $LAB/ch15/fork-network/platform/network
 * branch            915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5 -> FETCH_HEAD
$ git show --stat --format="%h %s" FETCH_HEAD
915a81e Add staging config for debugging

 staging.env | 1 +
 1 file changed, 1 insertion(+)
$ cd ../..
```
<!-- /snippet -->

The upstream served a commit that none of its refs reaches, because the object is in the store it shares with the fork. Deleting the fork removes refs and nothing else:

<!-- snippet: ch15/fork-network/07-delete-fork -->
```text
# The fork is deleted: its refs go. The object database is not touched.
$ git -C platform/network.git for-each-ref --format='delete %(refname)' refs/namespaces/you | git -C platform/network.git update-ref --stdin
$ git -C platform/network.git for-each-ref --format="%(refname)"
refs/namespaces/acme-ml/refs/heads/main
$ git -C platform/network.git cat-file -t 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
commit
```
<!-- /snippet -->

<!-- snippet: ch15/fork-network/08-prune -->
```text
# Only when the server prunes unreachable objects does the commit cease to exist there:
$ git -C platform/network.git gc --quiet --prune=now
$ git -C platform/network.git cat-file -t 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
fatal: git cat-file: could not get object info
[exit status: 128]
```
<!-- /snippet -->

In the model the commit dies when the server prunes unreachable objects. For GitHub, the report found no documented retention period for unreachable commits. The manual page of Git namespaces carries its own warning: namespaces "are not effective for read access control".

**Picture.**

```text
              platform: one object database for the whole network
  +-------------------------------------------------------------------------+
  |  objects:  ... bf7889c (main)   915a81e (the commit with the key)       |
  |                                                                         |
  |  refs of acme-ml/prompt-registry      refs of you/prompt-registry       |
  |    refs/heads/main -> bf7889c           refs/heads/main -> bf7889c      |
  |                                         refs/heads/debug/staging-config |
  |                                                          -> 915a81e     |
  +-------------------------------------------------------------------------+
        ^ a request by ID through either name finds the object
```

**State table.** Operations of this section, by what they change:

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| Fork (web interface, or `gh repo fork`) | unchanged | unchanged | unchanged | unchanged | unchanged; with `--clone`, a new clone whose remotes are the fork and its parent | a new repository exists | the fork relationship is recorded |
| `gh repo sync OWNER/FORK` | unchanged | unchanged | unchanged | unchanged | unchanged | the fork's branch is fast-forwarded to its parent's; with `--force`, hard reset to it | unchanged |
| Delete a fork | unchanged | unchanged | unchanged | unchanged | your remote for it now fails | its refs are gone | objects can remain reachable through the network |

According to `gh repo sync --help`, a sync is a fast-forward "except when the `--force` flag is specified, then the two branches will be synced using a hard reset". 🔴 `gh repo sync --force` discards commits on the destination branch that the source does not have. Preview with `git log upstream/main..origin/main` after a fetch; recovery needs a clone that still has those commits; it is appropriate only when the fork's branch is meant to be an exact copy of its parent. The Git commands for keeping a fork current are in Chapter 12, section 12.10, and the full fork workflow is in [Chapter 17](ch17-pull-requests.md) and [Chapter 27](ch27-open-source-team-workflows.md).

**In production.** The CTO's first question. The key was published the moment the push to the public fork finished. Deleting the fork changed which names list the commit, not whether the object can be fetched. Revoke the key first, then decide whether removal is worth requesting; a secret store and push protection are the prevention ([Chapter 21B](ch21b-repository-security-incident-response.md)).

## 15.8 Issues: structure, and the keywords that close them

**In one sentence.** An issue is a numbered record in GitHub's database for a unit of work or a report, which since 2025 can have a type, a parent, children and dependencies.

**Precisely.** To the REST API "every pull request is an issue, but not every issue is a pull request" ([REST reference](https://docs.github.com/en/rest/issues/issues)), which is why `#12` can be either and why issue endpoints return both. The structure added in 2025 and 2026 (report, section 2):

| Feature | Facts | Since |
|---|---|---|
| Sub-issues | up to 100 per parent, eight levels deep; a sub-issue may live in another repository ([docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)) | generally available 9 April 2025 ([changelog](https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/)) |
| Issue types | defined per organization, up to 25; the defaults are task, bug and feature ([docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types-in-an-organization)) | 9 April 2025 |
| Dependencies | "blocked by" and "blocking", up to 50 links per relationship type ([docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies)) | 21 August 2025 ([changelog](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)) |
| Issue fields | typed metadata defined per organization; four default fields (Priority, Effort, Start date, Target date) | 2 July 2026 ([changelog](https://github.blog/changelog/2026-07-02-issue-fields-are-now-generally-available/)) |

Types and fields belong to an organization, one more thing a personal account does not have.

**Closing keywords.** Nine words link a pull request or a commit to an issue: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`, followed by `#N` for the same repository or `OWNER/REPO#N` for another, in any letter case, with an optional colon ([linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)). The rules that explain every "why did it not close" question are on the same page:

- In a pull request description the keywords are interpreted **only when the pull request targets the default branch**. Against any other branch they are ignored: no link is made and nothing closes.
- In a commit message the issue closes when the commit reaches the default branch, and the pull request that carried the commit is not listed as linked.
- The issue closes at merge time, not when the pull request is opened.

> **Git, not GitHub.** The keyword is text in a commit object or in a database field. Git does nothing with it (section 15.2). It also travels with the message: a cherry-picked or rebased copy of the commit carries the same words, and they act when that copy reaches a default branch.

`gh issue create`, `list`, `view`, `edit`, `close` and `develop` cover daily work; `gh issue develop N --checkout` creates a branch linked to issue N and switches to it (`gh issue develop --help`). The installed 2.88.1 has no flags for types, parents or dependencies; `gh issue create --type` and `--parent` arrived in 2.94.0 ([release notes](https://github.com/cli/cli/releases/tag/v2.94.0)).

**In production.** A fix is merged into `release/2.4` with "Fixes #812" in the description. The issue stays open and the customer is told it is unresolved. Nothing failed: the pull request did not target the default branch. Teams that ship from release branches close issues by hand or by automation, and say so in `CONTRIBUTING.md`.

## 15.9 Labels and milestones

A **label** classifies issues, pull requests and discussions within one repository. Every new repository receives default labels, among them `bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `invalid`, `question` and `wontfix`; organization owners can change the defaults for new repositories. Creating a label needs Write, applying one needs Triage ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)). Labels are more than decoration when something reads them: an issue form can apply labels (section 15.13), generated release notes group pull requests by label (section 15.12), and workflows can react to them.

A **milestone** groups issues and pull requests toward a date and shows a completion percentage ([about milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones)). It is not a Git tag and not a release: a milestone called `v0.3.0` promises nothing about which commit ships.

`gh label create`, `edit`, `list`, `delete` and `clone` manage labels; `gh label clone` copies a label set from one repository to another, which is how a team keeps forty repositories consistent. The CLI has no milestone command in 2.88.1; milestones are reached through `gh api` on `repos/{owner}/{repo}/milestones` ([REST reference](https://docs.github.com/en/rest/issues/milestones)).

## 15.10 Projects, Discussions and wikis

**Projects** is the planning layer: "an adaptable table, board, and roadmap" over issues and pull requests, owned by a user or an organization, not by a repository, with up to 50 fields and, since April 2025, up to 50,000 items ([about Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects), [changelog](https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/)).

> **Outdated advice.** "Projects (classic)", a board attached to one repository, was sunset on GitHub.com on 23 August 2024, and GitHub CLI versions older than 2.82.1 fail to fetch projects ([sunset notice](https://github.blog/changelog/2024-05-23-sunset-notice-projects-classic/)). `gh project` needs the `project` scope: `gh auth refresh -s project` (`gh pr create --help`).

**Discussions** is a forum beside the issue tracker: announcements, questions with a marked answer, polls. Someone with the Maintain or Admin role must enable it for a repository; organization-level discussions span repositories ([about discussions](https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions)). The working rule: an issue can be done and closed; a question or an open-ended idea is a discussion.

A **wiki** is documentation in a second Git repository, cloned as `OWNER/REPO.wiki.git`; only changes pushed to its default branch are shown. By default people with Write can edit it. Wikis in private repositories need a paid plan, and a wiki has a soft limit of 5,000 files ([about wikis](https://docs.github.com/en/communities/documenting-your-project-with-wikis/about-wikis)). Because it is a separate repository, a wiki is not reviewed through pull requests, not covered by the rulesets of the main repository, and not included when you clone or mirror the code. Documentation that must be reviewed with the code belongs in `docs/`.

## 15.11 Packages and the container registry

GitHub Packages hosts registries for npm, RubyGems, Maven, Gradle, Docker and NuGet; the Container registry at `ghcr.io` is the home for Docker and OCI images ([introduction to Packages](https://docs.github.com/en/packages/learn-github-packages/introduction-to-github-packages)). Four facts shape how you use it:

- **A package is not Git data and not part of a repository.** An image at `ghcr.io/OWNER/IMAGE` belongs to a user or an organization and is "not linked to a repository by default"; it can be linked, and its access can be inherited from a repository or set separately ([container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)).
- **Authentication is an exception to the token advice.** "GitHub Packages only supports authentication using a personal access token (classic)"; inside a workflow the job's `GITHUB_TOKEN` is used instead. A fine-grained token cannot log in to `ghcr.io` ([Chapter 16](ch16-authentication.md)).
- **Public packages are free**; private packages get an allowance according to the plan.
- **Provenance is separate from storage.** An artifact attestation is a signed claim about which workflow run built an artifact from which commit, checked with `gh attestation verify`; attestations work for public repositories on every plan and for private repositories only on Enterprise Cloud ([artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)).

> **Outdated advice.** `docker.pkg.github.com`, the old Docker registry of GitHub Packages, was closed on 24 February 2025 ([changelog](https://github.blog/changelog/2025-01-23-legacy-docker-registry-closing-down/)). Use `ghcr.io`.

Publishing an image from a workflow is workflow 6 in [Chapter 20A](ch20a-actions-fundamentals.md).

## 15.12 Releases: a Git tag versus a GitHub Release

**In one sentence.** A tag is a Git ref that names a commit; a release is a GitHub record that points at a tag name and adds a title, notes, files and flags.

**Analogy.** A tag is the mark stamped on a casting; a release is the catalogue page for it, with a description and a download. The page can be rewritten without touching the metal. The analogy breaks in one dangerous place: asking for a page for a mark that does not exist makes the platform stamp the mark for you, on whatever is at the front of the line.

**Precisely.** Tags are [Chapter 14B](ch14b-config-tags-signing.md): lightweight or annotated, under `refs/tags/`, moved between repositories by `git push` and `git fetch`. On the GitHub side ([about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)):

- "Releases are based on Git tags." A release adds a title, notes, uploaded assets and three flags: draft, pre-release, latest. Managing releases needs Write.
- **Creating a release can create the tag.** The REST reference describes `target_commitish` as the value "that determines where the Git tag is created from", unused if the tag already exists, defaulting to the default branch ([create a release](https://docs.github.com/en/rest/releases/releases#create-a-release)). The CLI says the same about itself:

<!-- snippet: ch15/gh-help/02-release-create -->
```text
$ gh release create --help | sed -n '/^If a matching git tag/,/^If the tag is not annotated/p'
If a matching git tag does not yet exist, one will automatically get created
from the latest state of the default branch.
Use `--target` to point to a different branch or commit for the automatic tag creation.
Use `--verify-tag` to abort the release if the tag doesn't already exist.
To fetch the new tag locally after the release, do `git fetch --tags origin`.

To create a release from an annotated git tag, first create one locally with
git, push the tag to GitHub, then run this command.
Use `--notes-from-tag` to get the release notes from the annotated git tag.
If the tag is not annotated, the commit message will be used instead.
$ gh release create --help | grep -E -- '--(verify-tag|target|notes-from-tag|generate-notes|draft|prerelease) '
  -d, --draft                        Save the release as a draft instead of publishing it
      --generate-notes               Automatically generate title and notes for the release via GitHub Release Notes API
      --notes-from-tag               Fetch notes from the tag annotation or message of commit associated with tag
  -p, --prerelease                   Mark the release as a prerelease
      --target branch                Target branch or full commit SHA (default [main branch])
      --verify-tag                   Abort in case the git tag doesn't already exist in the remote repository
$ gh release delete --help | grep -- '--cleanup-tag'
      --cleanup-tag   Delete the specified tag in addition to its release
```
<!-- /snippet -->

This transcript is marked volatile: it is the help text of gh 2.88.1 and may read differently in your version.

- **Generated notes** list merged pull requests and contributors, and are configured in `.github/release.yml`, where labels and authors can be excluded or grouped ([generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)). Their quality is the quality of your pull request titles and labels.
- **Immutable releases**, generally available since 28 October 2025: once published, the tag is locked to its commit and cannot be deleted while the release exists; assets cannot be changed; the tag name can never be reused; and a signed release attestation is generated, checked with `gh release verify` ([immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases), [changelog](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/)). The documented order is: create a draft, attach the assets, publish.

**Inside `.git`.** A release leaves no trace in any clone. The tag does, and only after a fetch.

**See it.** You create an annotated tag and push it, the way a release is cut on purpose:

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

Two lines for one tag: the tag object, and the commit it points at (`^{}`). Then Asha merges one more commit, and someone creates a release v0.3.0 on the platform without creating a tag first. A plain `git tag` on the bare repository stands in for what the platform does then:

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

The server has a tag that your clone has never seen. One line this time: no tag object, only a ref that names a commit.

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

<!-- snippet: ch15/tag-vs-release/04-two-kinds -->
```text
$ git for-each-ref --format="%(refname:short)  %(objecttype)  tagger=%(taggername)  %(subject)" refs/tags
v0.2.0  tag  tagger=Lab User  prompt-registry 0.2.0: first tagged version
v0.3.0  commit  tagger=  Document that versions are immutable
```
<!-- /snippet -->

<!-- snippet: ch15/tag-vs-release/05-describe -->
```text
$ git describe origin/main
v0.2.0-1-g89837fa
$ git describe --tags origin/main
v0.3.0
```
<!-- /snippet -->

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

> **Unverified.** That a tag created by the release API is lightweight is an inference: the CLI help tells you to create annotated tags yourself. Lab 25.1 has you check with `git cat-file -t`. Also not stated in the documentation read: what happens to a release when its tag is deleted, and whether immutable releases are limited to certain plans (report, section 2, flags).

**State table.**

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git tag -a v0.2.0` then `git push origin v0.2.0` | unchanged | unchanged | unchanged | unchanged | `refs/tags/v0.2.0` and a tag object | the tag ref and tag object are created | the tag is listed; no release exists |
| `gh release create v0.2.0 --verify-tag --generate-notes` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | a release pointing at the existing tag |
| `gh release create v0.3.0` when no such tag exists | unchanged | unchanged | unchanged | unchanged | unchanged, until you fetch | a tag is created from the default branch, or from `--target` | a release, and a tag you did not make |
| `gh release delete v0.3.0` | unchanged | unchanged | unchanged | unchanged | unchanged | the tag stays, unless `--cleanup-tag` is given | the release is gone |

**In production.** A workflow builds a container image when a tag `v*` is pushed and derives the version with `git describe`. A product manager creates "v1.9.0" in the web interface on Friday evening. The tag lands on whatever `main` was at that second, the workflow fires, and the version string in the artifact is wrong, because the tag is lightweight. Three controls close the gap: a tag ruleset that restricts who may create `v*` tags ([Chapter 18](ch18-branch-protection.md)), `--verify-tag` in every script, and immutable releases.

## 15.13 Templates, issue forms and community health files

**In one sentence.** Community health files are tracked files with well-known names that GitHub finds and uses to guide the people who interact with a repository.

**Precisely.** GitHub looks for each file in `.github/`, then the repository root, then `docs/` ([default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)).

| File | What GitHub does with it | Source |
|---|---|---|
| `README.md` | renders it on the repository's front page | [about READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes) |
| `LICENSE` | detects the license and shows it; without one, default copyright applies and nobody is permitted to reuse the code | [licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository) |
| `CONTRIBUTING.md` | links it when someone opens an issue or pull request; since August 2025 also shows a Contributing tab | [contributor guidelines](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors), [changelog](https://github.blog/changelog/2025-08-07-contributing-guidelines-now-visible-in-repository-tab-and-sidebar/) |
| `SECURITY.md` | shows it as the security policy: how to report a vulnerability | [security policy](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository) |
| `CODE_OF_CONDUCT.md` | counts it in the community profile | [code of conduct](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/adding-a-code-of-conduct-to-your-project) |
| `.github/ISSUE_TEMPLATE/*.md`, `*.yml`, `config.yml` | offers them in the "new issue" chooser; read from the default branch | [issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository) |
| `pull_request_template.md` in the root, `docs/` or `.github/` | pre-fills the description of a new pull request; read from the default branch | [pull request template](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository) |
| `.github/CODEOWNERS` | requests reviews from owners of changed paths | [Chapter 19](ch19-codeowners.md) |
| `.github/workflows/*.yml` | defines GitHub Actions workflows | [Chapter 20A](ch20a-actions-fundamentals.md) |

An **issue form** is a YAML file that turns the free-text issue into a form with required fields. This one is from the practice repository:

<!-- snippet: ch15/repo-layout/02-issue-form -->
```text
$ cat .github/ISSUE_TEMPLATE/1-bug.yml
name: Bug report
description: Something does not work as documented.
title: "[Bug]: "
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting. Do not report vulnerabilities here: see SECURITY.md.
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: What did you do, what did you expect, and what happened instead?
    validations:
      required: true
  - type: input
    id: commit
    attributes:
      label: Commit
      description: The output of `git rev-parse --short HEAD` in your clone.
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Relevant output
      description: Paste the command and its output. It is formatted as code automatically.
      render: shell
```
<!-- /snippet -->

Every key and element type in it is from the syntax reference, which also has `dropdown`, `checkboxes` and `upload` elements and the top-level keys `assignees`, `projects` and `type` ([syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)). The file was parsed with a YAML parser here; only GitHub validates a form, which Lab 19.1 checks. The label it names, `bug`, is a default label.

<!-- snippet: ch15/repo-layout/03-chooser-and-pr-template -->
```text
$ cat .github/ISSUE_TEMPLATE/config.yml
blank_issues_enabled: false
$ cat .github/pull_request_template.md
## What changed

<!-- One or two sentences. Link the issue: "Fixes #123" closes it when this merges into the default branch. -->

## Why

## How it was tested

- [ ] `python3 -m unittest discover -s tests` passes
- [ ] New behavior has a test

## Checklist

- [ ] The pull request does one thing
- [ ] No credentials, tokens, datasets or model files are in the diff
```
<!-- /snippet -->

`blank_issues_enabled: false` removes the blank issue from the chooser for people with the Read or Triage role; people with Write still see it, according to the same page. A pull request template is plain Markdown; content inside an HTML comment is hidden in the rendered description ([writing syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#hiding-content-with-comments)), so the comment guides the author and does not clutter the result. Issue forms cannot be used for pull requests.

Unlike settings, these files are versioned and reviewed like code. An organization can also supply defaults: a public repository named `.github` holds health files for every repository of the account that lacks its own, except a license (same page as above).

> **Unverified.** GitHub's syntax page still carries the note that issue forms are in public preview. The report could not determine whether that note is current or stale.

The **community profile** of a public repository is a checklist of these files; an issue form counts only when it has valid `name` and `description` keys ([community profiles](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)).

## 15.14 A professional repository layout, file by file

The layout below is a convention, not a GitHub requirement. GitHub reads the files of section 15.13 and nothing else in it.

```text
project/
├── .github/
│   ├── workflows/
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── src/
├── tests/
├── docs/
├── scripts/
├── configs/
├── .gitignore
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── SECURITY.md
├── pyproject.toml
└── Dockerfile
```

The same layout as a real repository, listed by Git:

<!-- snippet: ch15/repo-layout/01-tracked-files -->
```text
$ git ls-files
.github/CODEOWNERS
.github/ISSUE_TEMPLATE/1-bug.yml
.github/ISSUE_TEMPLATE/2-feature.yml
.github/ISSUE_TEMPLATE/config.yml
.github/pull_request_template.md
.gitignore
CONTRIBUTING.md
Dockerfile
LICENSE
README.md
SECURITY.md
configs/default.yaml
docs/architecture.md
pyproject.toml
scripts/release.sh
src/prompt_registry/__init__.py
src/prompt_registry/registry.py
tests/test_registry.py
```
<!-- /snippet -->

There is no `.github/workflows/` in the listing. Git tracks files, not directories ([Chapter 4](ch04-working-tree.md)), so the directory appears with the first workflow file in [Chapter 20A](ch20a-actions-fundamentals.md).

| Path | Read by | Purpose, and the mistake it prevents |
|---|---|---|
| `.github/workflows/` | GitHub Actions | CI and delivery, reviewed like code. Write can change what runs with the repository's secrets, so this directory deserves a code owner. |
| `.github/CODEOWNERS` | GitHub | Who is asked to review which paths. Only a request until a rule requires it ([Chapter 19](ch19-codeowners.md)). |
| `.github/pull_request_template.md` | GitHub | Makes every description answer the same questions: what, why, how tested. |
| `src/` | your build tool | The package lives under `src/`, so that it is importable only on purpose (installed, or put on the path by the tests) and never by accident from the current directory. |
| `tests/` | your test runner | Kept apart from the package so that the tests are not shipped with it. |
| `docs/` | people; GitHub for health files | Documentation that changes in the same pull request as the code it describes. |
| `scripts/` | people, CI | Release and deploy commands as files with history. |
| `configs/` | the application | Configuration without secrets. |
| `.gitignore` | Git | Keeps build output, virtual environments and local secret files out of the index ([Chapter 4](ch04-working-tree.md)). It does not untrack what is already tracked. |
| `README.md` | GitHub, people | What this is, how to run it, where to go next. |
| `LICENSE` | GitHub, lawyers | The terms of reuse. Without it nobody outside may use the code, whatever the visibility. |
| `CONTRIBUTING.md` | GitHub, contributors | How a change gets in: branch names, tests, review. |
| `SECURITY.md` | GitHub, reporters | Where to report a vulnerability privately, so that the first report is not a public issue. |
| `pyproject.toml` | Python tools | Project metadata and tool configuration in one file. |
| `Dockerfile` | Docker | How the service image is built. The one in the demo was not built here, because nothing may be downloaded while authoring. |

Two checks that belong to the layout. A local secret file must be ignored before the first commit, and you can ask Git which rule ignores it:

<!-- snippet: ch15/repo-layout/04-ignored-secret -->
```text
$ printf 'LLM_API_KEY=FAKE-KEY-for-the-lab\n' > .env
$ git status --short
$ git check-ignore -v .env
.gitignore:10:.env	.env
```
<!-- /snippet -->

And the tests must run from a fresh clone with one documented command, leaving the working tree clean:

<!-- snippet: ch15/repo-layout/05-tests -->
```text
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ git status --short
```
<!-- /snippet -->

[Chapter 28](ch28-ai-ml-workflows.md) grows this skeleton into an AI/ML project layout.

## 15.15 Repository limits

GitHub's limits come in three kinds: enforced, recommended, and display limits. Mixing them up produces both needless worry and real outages.

| Limit | Value | Kind | Source |
|---|---|---|---|
| One file in a push | warning above 50 MiB; blocked above 100 MiB | enforced | [large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github) |
| One file added in the browser | 25 MiB | enforced | same page |
| One push | 2 GB | enforced | [repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits) |
| Repository size | "ideally less than 1 GB, and less than 5 GB is strongly recommended" | recommended | large files page |
| Repository size on disk | 10 GB recommended maximum | recommended | repository limits page |
| Entries in one directory; directory depth; branches | 3,000; 50; 5,000 | recommended | repository limits page |
| Pull request diff | 20,000 lines or 1 MB that can be loaded; 300 files | display | repository limits page |
| Commits listed in a pull request or comparison | 250 | display | repository limits page |
| "Rebase and merge" | 100 commits | enforced | repository limits page |
| Repositories per organization or account | 100,000 | enforced | repository limits page |
| Release assets | 1,000 per release, each under 2 GiB | enforced | [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases) |

The two size recommendations sit on two pages and differ; both were read on 2 October 2026. Treat 1 GB as the target and 10 GB as the point where GitHub expects problems.

The file limit applies to every object a push sends, not to the files in your working tree. A file that you deleted in a later commit is still in history, and a first push sends all of history:

<!-- snippet: ch15/large-objects/01-gone -->
```text
$ git log --oneline -3
39c4105 Move the classifier out of Git
c7182c9 Add trained intent classifier
bf7889c Add contribution guide, security policy and templates
$ git ls-files | grep -c classifier
0
```
<!-- /snippet -->

<!-- snippet: ch15/large-objects/02-still-in-history -->
```text
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1 == "blob"' | sort -k2,2nr | head -3
blob 3145728 models/intent-classifier.bin
blob 1324 tests/test_registry.py
blob 996 src/prompt_registry/registry.py
```
<!-- /snippet -->

<!-- snippet: ch15/large-objects/03-which-commit -->
```text
$ git log --oneline --diff-filter=A -- models/intent-classifier.bin
c7182c9 Add trained intent classifier
```
<!-- /snippet -->

`git rev-list --objects --all` lists every reachable object with its path, `git cat-file --batch-check` adds type and size, and the sort puts the largest blob first. The model file is gone from the working tree and still 3 MiB of the repository. Had it been 300 MiB, the push would be rejected for commit `c7182c9`. The remedies are rewriting unpushed history ([Chapter 9](ch09-rebase.md)) or Git LFS ([Chapter 22](ch22-git-lfs.md)), and for a model file the better answer is usually a registry ([Chapter 28](ch28-ai-ml-workflows.md)).

## 15.16 The GitHub CLI

**In one sentence.** `gh` is a client for GitHub's API that knows which repository you are in, so the GitHub objects of section 15.2 become reachable from the directory where your Git data is.

**Precisely.** `gh` is not Git and does not replace it. It calls the REST and GraphQL APIs with a stored token, runs `git` for you where a task needs both (`gh repo clone`, `gh pr checkout`), and can act as Git's credential helper ([Chapter 16](ch16-authentication.md)). The command families of the installed version:

<!-- snippet: ch15/gh-help/01-families -->
```text
$ gh --help | sed -n '/^CORE COMMANDS/,/^HELP TOPICS/p' | sed '$d'
CORE COMMANDS
  auth:          Authenticate gh and git with GitHub
  browse:        Open repositories, issues, pull requests, and more in the browser
  codespace:     Connect to and manage codespaces
  gist:          Manage gists
  issue:         Manage issues
  org:           Manage organizations
  pr:            Manage pull requests
  project:       Work with GitHub Projects.
  release:       Manage releases
  repo:          Manage repositories

GITHUB ACTIONS COMMANDS
  cache:         Manage GitHub Actions caches
  run:           View details about workflow runs
  workflow:      View details about GitHub Actions workflows

ALIAS COMMANDS
  co:            Alias for "pr checkout"

ADDITIONAL COMMANDS
  agent-task:    Work with agent tasks (preview)
  alias:         Create command shortcuts
  api:           Make an authenticated GitHub API request
  attestation:   Work with artifact attestations
  completion:    Generate shell completion scripts
  config:        Manage configuration for gh
  copilot:       Run the GitHub Copilot CLI (preview)
  extension:     Manage gh extensions
  gpg-key:       Manage GPG keys
  label:         Manage labels
  licenses:      View third-party license information
  preview:       Execute previews for gh features
  ruleset:       View info about repo rulesets
  search:        Search for repositories, issues, and pull requests
  secret:        Manage GitHub secrets
  ssh-key:       Manage SSH keys
  status:        Print information about relevant issues, pull requests, and notifications across repositories
  variable:      Manage GitHub Actions variables
```
<!-- /snippet -->

(Volatile: this is gh 2.88.1.) The families you will use, with flags that were each checked against `--help` of that version:

| Family | Subcommands you need | Reaches | Verified flags worth knowing |
|---|---|---|---|
| `gh auth` | `login`, `status`, `setup-git`, `refresh`, `switch`, `token`, `logout` | the stored token | `--hostname`, `--git-protocol`, `--scopes`, `--with-token` (reads standard input) |
| `gh repo` | `create`, `clone`, `fork`, `view`, `edit`, `sync`, `set-default`, `list`, `archive`, `rename`, `delete`, `deploy-key`, `license`, `gitignore` | repositories and their settings | `create --public --source=. --remote=origin --push`; `view --json`; `edit` as in section 15.5 |
| `gh issue` | `create`, `list`, `view`, `edit`, `close`, `comment`, `develop` | issues | `create --title --body --label`; `develop --checkout` |
| `gh pr` | `create`, `list`, `status`, `view`, `checkout`, `checks`, `diff`, `review`, `ready`, `merge`, `update-branch`, `revert` | pull requests ([Chapter 17](ch17-pull-requests.md)) | `create --fill --draft --base`; `checks --watch --required`; `merge --squash --merge --rebase --auto --delete-branch --match-head-commit` |
| `gh release` | `create`, `list`, `view`, `edit`, `upload`, `download`, `delete`, `verify`, `verify-asset` | releases | section 15.12 |
| `gh run`, `gh workflow`, `gh cache` | `run list`, `view`, `watch`, `rerun`, `download`; `workflow list`, `run`, `view` | Actions ([Chapter 20B](ch20b-actions-delivery-debugging.md)) | covered there |
| `gh secret`, `gh variable` | `set`, `list`, `delete`; `variable get` | Actions, Dependabot and Codespaces secrets | `secret set NAME` reads the value from a prompt or standard input; values "are locally encrypted before being sent" |
| `gh ruleset` | `list`, `view`, `check` | rulesets, read-only | `check --default`; `list --org` |
| `gh api` | one command | everything else | section 15.17 |

<!-- snippet: ch15/gh-help/04-ruleset -->
```text
$ gh ruleset --help | sed -n '/^AVAILABLE COMMANDS/,/^FLAGS/p' | sed '$d'
AVAILABLE COMMANDS
  check:         View rules that would apply to a given branch
  list:          List rulesets for a repository or organization
  view:          View information about a ruleset
```
<!-- /snippet -->

`gh ruleset` can list, view and check. It cannot create or change a ruleset, so rulesets are automated through `gh api` ([Chapter 18](ch18-branch-protection.md)).

Four behaviors explain most surprises:

- **Which repository?** Inside a clone, `gh` picks the repository from your remotes. With a fork there are two candidates, and `gh repo set-default` records which one "to use when querying the GitHub API" for pull requests, issues, releases and Actions. Outside a clone, or to override, pass `-R OWNER/REPO` or set `GH_REPO`.
- **Machine-readable output.** Most listing commands take `--json FIELDS`, then `--jq EXPRESSION` or `--template`; the filter language is built in (`gh help formatting`). `--json` without a field list prints the available fields.
- **Exit codes.** 0 for success, 1 for failure, 2 when cancelled, 4 when authentication is required; `gh pr checks` adds 8 for pending checks (`gh help exit-codes`, `gh pr checks --help`). Scripts should test them and not parse human-readable output.
- **Its own token.** `GH_TOKEN` in the environment takes precedence over the stored login (`gh help environment`): a stale one in a shell profile explains "gh works in one terminal and not in another".

> **Version note.** Older behavior: gh 2.88.1, installed here and dated 12 March 2026, has no `gh discussion`, no `gh skill`, no `gh repo read-file`, and no flags for issue types, sub-issues or dependencies. Current behavior: gh 2.102.0 of 30 September 2026 has them (`discussion` and `skill` in preview), adds `gh pr checkout --worktree`, and offers to install official extensions such as `gh stack` for stacked pull requests. Since: 2.89.0 to 2.102.0 ([releases](https://github.com/cli/cli/releases), [manual](https://cli.github.com/manual/gh)). Recommended: upgrade, because six of those releases contain security fixes (research notes, section 9). From 2.91.0 the CLI collects pseudonymous telemetry unless you opt out with `gh config set telemetry disabled` ([changelog](https://github.blog/changelog/2026-04-22-github-cli-opt-out-usage-telemetry/)). The two versions were not compared flag by flag, so check `--help` after upgrading.

> **Outdated advice.** The `gh-copilot` extension stopped functioning on 25 October 2025 ([changelog](https://github.blog/changelog/2025-09-25-upcoming-deprecation-of-gh-copilot-cli-extension/)). Extensions in general "are not verified, signed, or endorsed by GitHub" ([manual](https://cli.github.com/manual/gh_extension)): installing one is running someone's code with your token.

**In production.** A release script runs `gh release create "$VERSION" --generate-notes`. On the day `VERSION` holds a typo, a tag that nobody intended exists on the default branch. `--verify-tag` turns that into an error before anything is created.

## 15.17 `gh api`, the REST API, GraphQL and rate limits

**In one sentence.** Everything GitHub shows you comes from an API that you can call yourself; `gh api` adds your token, the host and the placeholders, and prints the JSON.

**Precisely.** The **REST API** is a set of URLs under `https://api.github.com`, one per resource, such as `GET /repos/{owner}/{repo}/pulls`. `gh api` takes the path and fills in `{owner}`, `{repo}` and `{branch}` from the current repository:

```bash
gh api repos/{owner}/{repo}                                   # one object
gh api repos/{owner}/{repo} --jq '{full_name, default_branch, visibility, fork}'
gh api repos/{owner}/{repo}/pulls --jq '.[] | "#\(.number) \(.title)"'
gh api repos/{owner}/{repo}/rulesets --jq '.[] | "\(.id) \(.name) \(.enforcement)"'
gh api rate_limit --jq '.resources.core'
gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo}/pulls --paginate --jq '.[].number'
```

The paths and field names were checked against the REST reference on 2 October 2026 ([repositories](https://docs.github.com/en/rest/repos/repos), [pulls](https://docs.github.com/en/rest/pulls/pulls), [rules](https://docs.github.com/en/rest/repos/rules), [rate limit](https://docs.github.com/en/rest/rate-limit/rate-limit)). The commands were not run. The flags are those of the installed CLI:

<!-- snippet: ch15/gh-help/03-api-flags -->
```text
$ gh api --help | sed -n '/^FLAGS/,/^INHERITED FLAGS/p' | sed '$d'
FLAGS
      --cache duration        Cache the response, e.g. "3600s", "60m", "1h"
  -F, --field key=value       Add a typed parameter in key=value format (use "@<path>" or "@-" to read value from file or stdin)
  -H, --header key:value      Add a HTTP request header in key:value format
      --hostname string       The GitHub hostname for the request (default "github.com")
  -i, --include               Include HTTP response status line and headers in the output
      --input file            The file to use as body for the HTTP request (use "-" to read from standard input)
  -q, --jq string             Query to select values from the response using jq syntax
  -X, --method string         The HTTP method for the request (default "GET")
      --paginate              Make additional HTTP requests to fetch all pages of results
  -p, --preview strings       Opt into GitHub API previews (names should omit '-preview')
  -f, --raw-field key=value   Add a string parameter in key=value format
      --silent                Do not print the response body
      --slurp                 Use with "--paginate" to return an array of all pages of either JSON arrays or objects
  -t, --template string       Format JSON output using a Go template; see "gh help formatting"
      --verbose               Include full HTTP request and response in the output
```
<!-- /snippet -->

Rules of the road, each from the help text or the linked page:

- **Method.** `GET` by default, `POST` as soon as you add a field with `-f` or `-F`. To send parameters with a `GET`, say `-X GET`.
- **Fields.** `-f key=value` sends a string. `-F key=value` converts `true`, `false`, `null` and integers to JSON types and reads `@file`.
- **Pagination.** Lists return 30 items per page unless you ask otherwise ([pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)). `--paginate` follows the pages; `--slurp` wraps them into one array.
- **Versioning.** The REST API is versioned by date through the `X-GitHub-Api-Version` header. Without the header a request gets version `2022-11-28`, which is supported until 10 March 2028; `2026-03-10` is the first version with breaking changes; an unsupported version answers `410 Gone` ([API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions), [changelog](https://github.blog/changelog/2026-03-12-rest-api-version-2026-03-10-is-now-available/)). The CLI pins its own REST calls to `2022-11-28` since 2.87.0 ([release](https://github.com/cli/cli/releases/tag/v2.87.0)). In a script that must keep working, send the header explicitly.
- **Not found means "not for you".** For a private resource and a token without access, the API answers `404 Not Found`, not `403`, "to avoid confirming the existence of private repositories" ([troubleshooting](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api#404-not-found-for-an-existing-resource)). [Chapter 16](ch16-authentication.md) builds its diagnosis on this.

**See it.** `--jq` takes the filter language of the `jq` program. The filters can be rehearsed offline with `jq` itself. The input here is `labs/ch15/api-examples/pulls-sample.json`, a practice document written for this course with the field names of the pull request list; it is not output from GitHub.

<!-- snippet: ch15/jq-rehearsal/02-several-fields -->
```text
$ jq -r '.[] | "#\(.number)  \(.user.login)  \(.head.ref) -> \(.base.ref)"' pulls-sample.json
#14  asha-rao  feature/list-names -> main
#15  ravi-menon  feature/sqlite-store -> main
#16  asha-rao  backport/empty-names -> release/0.1
```
<!-- /snippet -->

<!-- snippet: ch15/jq-rehearsal/03-select -->
```text
$ jq -r '.[] | select(.draft | not) | select(.base.ref == "main") | .number' pulls-sample.json
14
$ jq '[.[] | select(.user.login == "asha-rao")] | length' pulls-sample.json
2
```
<!-- /snippet -->

`.[]` iterates over the array, `\( )` interpolates a field into a string, `select` keeps the elements for which the condition holds, and `-r` prints strings without quotes. With `gh api`, the same filter goes after `--jq` and no `-r` is needed.

**GraphQL** is the second API: one endpoint, a typed schema, and a query that names exactly the fields wanted, so one call can replace several REST requests ([about the GraphQL API](https://docs.github.com/en/graphql/overview/about-the-graphql-api)). `gh api graphql -f query='...'` calls it. Some features exist in only one of the two APIs.

**Rate limits** ([rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)):

| Caller | Primary limit |
|---|---|
| No authentication | 60 requests per hour, per IP address |
| An authenticated user (your token, `gh`) | 5,000 requests per hour |
| A GitHub App installation | 5,000 per hour at minimum; 15,000 on Enterprise Cloud organizations |
| `GITHUB_TOKEN` in a workflow | 1,000 requests per hour per repository |

Secondary limits apply on top: at most 100 concurrent requests, and a points budget per minute. Exceeding a limit returns `403` or `429`, so a `403` is not always a permission problem; the `x-ratelimit-*` headers and `gh api rate_limit` say where you stand.

**In production.** A nightly job lists pull requests of sixty repositories with unauthenticated `curl`. It worked from a laptop and fails on the shared CI runner, where the sixty requests per hour of that IP address are spent before it starts. Unauthenticated limits were lowered on 8 May 2025, anonymous HTTPS clones included ([changelog](https://github.blog/changelog/2025-05-08-updated-rate-limits-for-unauthenticated-requests/)). The fix is an identity for the job, not a retry loop.

## 15.18 Webhooks and GitHub Apps: the integration model

**Polling** asks GitHub repeatedly whether something happened. A **webhook** reverses the direction: you register a URL and the events you care about on a repository, an organization or a GitHub App, and GitHub sends an HTTP request with a JSON payload when one occurs ([about webhooks](https://docs.github.com/en/webhooks/about-webhooks)). A `push` webhook carries the ref and the commit IDs before and after the push ([webhook events](https://docs.github.com/en/webhooks/webhook-events-and-payloads#push)), which is the information of a reflog line, delivered to your server.

A **GitHub App** is the identity an integration should have. It is installed on chosen repositories, holds fine-grained permissions, receives webhooks, and acts with installation tokens that expire after one hour. It is not tied to a person, so it does not stop working when someone leaves. GitHub's own guidance is that "GitHub Apps are preferred over OAuth apps" ([deciding when to build a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app)). The alternatives are a personal token, which acts as you everywhere you have access, and a machine user. [Chapter 16](ch16-authentication.md) compares the credentials and their lifetimes.

One fact for anyone who writes tooling: the API for check runs and check suites is available only to GitHub Apps (same page); the older commit statuses can be created with Write access (section 15.4).

> **Unverified.** Webhook delivery retries and signature validation were not researched for the Phase 0 report, and are not described here.

## 15.19 Organization governance in brief

What an organization gives you beyond a container, each item a GitHub object that no clone carries (report, sections 2 and 13; notes, section 13):

| Control | What it does | Plan |
|---|---|---|
| Base permission, teams, roles | section 15.4 | all |
| Required two-factor authentication | members without it lose access to the organization's resources until they enable it ([docs](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-two-factor-authentication-for-your-organization/requiring-two-factor-authentication-in-your-organization)) | all |
| Personal access token policy | allow or restrict each token type, set a maximum lifetime, require approval of fine-grained tokens ([docs](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)) | all |
| Repository rulesets; organization rulesets | rules on branches, tags and pushes ([Chapter 18](ch18-branch-protection.md)) | repository rulesets: public repositories on Free, all on paid plans; organization rulesets: Team |
| Custom properties | typed metadata on repositories that rulesets can target ([docs](https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization)) | availability on Free organizations not confirmed by the report |
| Audit log | who did what in the organization, 180 days, searchable ([docs](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)) | all; streaming and Git events on Enterprise Cloud, where Git events are retained for seven days and are not shown in the web interface ([Chapter 13](ch13-recovery.md), section 13.15; [Chapter 21B](ch21b-repository-security-incident-response.md), section 21B.8) |
| SAML single sign-on, IP allow lists, custom roles, enterprise policies | identity and network controls | Enterprise Cloud |

> **Unverified.** GitHub's documentation contradicts itself on whether organization rulesets need Enterprise or Team; the report prefers the later sources, which say Team ([changelog](https://github.blog/changelog/2025-06-16-organization-rulesets-now-available-for-github-team-plans/)).


## 15.20 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A member can read repositories nobody granted | the base permission, then the person's teams (section 15.4) | set the base permission on purpose; grant through teams | review both whenever people join |
| A person who left still has access | deploy keys and tokens are not membership: `gh repo deploy-key list` | remove the key; rotate what it could read | GitHub Apps and short-lived tokens ([Chapter 16](ch16-authentication.md)) |
| A commit from a deleted fork is still reachable | the network's shared object store (section 15.7) | revoke what it exposed ([Chapter 21B](ch21b-repository-security-incident-response.md)) | push protection; no secrets in Git |
| The issue did not close after the merge | `gh pr view N --json baseRefName,closingIssuesReferences`: wrong base, or no keyword | close by hand | document how issues close on release branches |
| `git describe` disagrees with the release page | `git cat-file -t TAG` prints `commit` (section 15.12) | describe with `--tags`, or tag properly under a new name | annotated tag first; `--verify-tag` |
| A push is rejected for a file that is not in the working tree | the pipeline of section 15.15 | rewrite unpushed history; LFS or a registry | size check before the first push |
| The issue form is missing from the chooser | invalid for GitHub, or not on the default branch ([validation errors](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/common-validation-errors-when-creating-issue-forms)) | fix on the default branch | review forms like code |
| `gh` acts on the wrong one of fork and upstream | `gh repo set-default --view` | `gh repo set-default OWNER/REPO`, or `-R` | set it once per clone |
| A script reports exactly 30 items, or created something by accident | no pagination; a field flag switched the method to `POST` | `--paginate`; `-X GET` | both in every script |
| `404` from the API for a repository you can open in the browser | the token lacks access: `gh auth status` ([Chapter 16](ch16-authentication.md)) | a credential with access | record each token's owner and resources |

## 15.21 When not to use it, and dangerous edge cases

- **A fork, a private repository or a deleted branch does not make a secret safe or gone.** Fork networks share Git data, upstream owners can read all forks, and visibility changes rewrite nothing.
- **Do not create releases for tags that do not exist.** Push the tag you mean, then `--verify-tag`.
- **Do not grant Write for convenience.** Write can merge, release, define code owners, and edit workflows and Actions secrets.
- **Do not build tooling on `gh`'s human-readable output or on a personal token.** Use `--json`, the version header, and a GitHub App for anything that must outlive you.
- **Visibility changes, transfers, renames and deletion act on GitHub objects that no clone can restore:** stars, watchers, forks' attachment, push rulesets, and the 90-day restore window that a non-empty fork network removes.
- **A public practice repository is public.** Never push real secrets, customer names or work code to it.

## 15.22 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `gh repo view`, `gh issue list`, `gh pr view`, `gh release list`, `gh ruleset list`, `gh auth status`, `gh api` with `GET`, `gh api graphql` with a `query` | 🟢 SAFE | nothing (a GraphQL `query` only reads, although it is sent as a `POST`) | not needed | not needed |
| `gh repo clone`, `gh pr checkout`, `gh release download` | 🟢 SAFE | local files and refs | not needed | delete them |
| `gh repo create --source=. --push` | 🟡 CAUTION | a repository on GitHub, a remote, a push | `git log`, `git status`; check `--public` or `--private` | `gh repo delete`; what reached a public repository is published |
| `gh issue create`, `gh pr create`, `gh label create`, `gh release create --verify-tag --draft` | 🟡 CAUTION | GitHub objects that notify people | `gh pr create --dry-run`; `--draft` | close or delete; notifications are not recalled |
| `gh repo edit` (features, merge methods), `gh repo fork`, `gh repo sync` | 🟡 CAUTION | settings; a new repository; a fast-forward | `gh repo view --json`; `git log HEAD..upstream/main` | set the previous value; delete the fork |
| `gh api` with `POST`, `PATCH`, `PUT`, `DELETE`; `gh api graphql` with a `mutation` | 🔴 DANGEROUS | whatever the endpoint says, with all your permissions | the `GET` first | depends on the endpoint; often none |
| `gh release create TAG` without `--verify-tag` | 🔴 DANGEROUS | may create a tag on the default branch and start tag workflows | `git ls-remote --tags origin TAG` | delete release and tag; consumers may have fetched it |
| `gh release delete --cleanup-tag`, `git push origin --delete TAG` | 🔴 DANGEROUS | a published version's name | `gh release view TAG` | re-create from the recorded commit ID |
| `gh repo sync --force` | 🔴 DANGEROUS | hard reset of the destination branch | `git log upstream/main..origin/main` after a fetch | a clone that still has the commits |
| `gh repo edit --visibility`, `gh repo delete`, `gh repo rename`, `gh repo archive` | 🔴 DANGEROUS | visibility with its side effects; the repository, its URL, its writability | section 15.5; ask who depends on the URL | visibility can be changed back, its side effects cannot; restore within 90 days unless the fork network is not empty |

Every 🔴 command here changes GitHub objects that no clone contains. Run the preview, which is always a read with the same tool, and name who is affected.

## 15.23 Version notes

The dated changes are given where they are used: accounts (15.3), pull request access (15.5), issues (15.8), Projects (15.10), the Docker registry (15.11), immutable releases (15.12), the CLI (15.16) and the REST API (15.17).

> **Version note.** Older behavior: tag protection rules guarded release tags. Current behavior: they were retired and migrated to tag rulesets. Since: 30 August 2024 ([sunset notice](https://github.blog/changelog/2024-05-29-sunset-notice-tag-protections/)). Recommended: a tag ruleset on your version pattern, plus immutable releases.

## 15.24 Practice

- **Labs 19.1 and 19.2** in the [Module 19 lab manual](../lab-manual/m19-github-platform.md): create the practice organization and repository, then inventory what in it is Git data and what is a GitHub object. Every later GitHub lab uses that repository.
- **Labs 25.1 and 25.2** in the [Module 25 lab manual](../lab-manual/m25-github-cli-api.md): a feature cycle with `gh`, and queries with `gh api`. Do them after Chapter 16.
- Answers: [Module 19](../solutions/m19-lab-answers.md), [Module 25](../solutions/m25-lab-answers.md).
- Replay any transcript with `labs/run ch15/<demo>`. Two drills; predict, then run:
  1. `ch15/fork-network`: between steps 7 and 8, clone the upstream namespace again and fetch the commit by ID. Does it work, and why?
  2. `ch15/large-objects`: push only a branch that never contained the model file to a new bare repository. Is the 3 MiB blob sent?

## 15.25 Interview questions

1. Take ten things on a repository's page. For each, is it Git data or a GitHub object, and how do you prove it from a terminal?
2. A commit with a credential was pushed to a fork of your public repository, and the fork was deleted. What is still true, what does GitHub document, and what do you do first?
3. A member has Read through the base permission, Triage through one team and Write through another. What can she do? Which setting do you check when she can do more than intended?
4. Explain a Git tag versus a GitHub Release. How can a release point at a commit nobody chose, and what prevents it?
5. `git describe` prints a different version than the release page. Root cause and evidence?
6. A pull request said "Fixes #812" and the issue is still open after the merge. Give three causes and how to tell them apart.
7. You must move a repository to another host without loss. What does a mirror clone carry, and how do you inventory the rest?
8. What changes and what does not when a public repository is made private? Answer for Git data, forks, stars, and someone who cloned it yesterday.
9. A script using `gh api` returns 30 results everywhere, and once created an issue by accident. Explain both.
10. When do you build a GitHub App instead of using a personal token or a machine user?

## 15.26 Sources

**Primary sources**

- GitHub Docs, read on 2 October 2026: [types of accounts](https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts), [repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization), [base permissions](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization), [repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility), [forks](https://docs.github.com/en/pull-requests/reference/forks), [linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue), [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases), [issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms), [community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), [repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits), [large files](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [Packages](https://docs.github.com/en/packages/learn-github-packages/introduction-to-github-packages), [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions), [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [webhooks](https://docs.github.com/en/webhooks/about-webhooks).
- The GitHub CLI: `gh <command> --help` of the installed 2.88.1 for every command and flag in this chapter; the [manual](https://cli.github.com/manual/gh) and [release notes](https://github.com/cli/cli/releases) for newer versions.
- The GitHub Changelog entries linked in the sections.
- Git: [gitnamespaces](https://git-scm.com/docs/gitnamespaces) for the model in section 15.7; [git-describe](https://git-scm.com/docs/git-describe), [git-rev-list](https://git-scm.com/docs/git-rev-list), [git-cat-file](https://git-scm.com/docs/git-cat-file), as installed with Git 2.55.0.

**Secondary sources**

- The Phase 0 report of this course, sections 2, 3, 4 and 12, and its research notes on the GitHub platform: the dated changes, the plan gates and the flags marked unverified here.
- Check Point Research, [Stargazers Ghost Network](https://research.checkpoint.com/2024/stargazers-ghost-network/), cited by the report.

**Videos** (optional; the report's assessments rest on captions and chapter lists, not on full viewing)

- [The ultimate beginner's guide to GitHub in 2026](https://www.youtube.com/watch?v=NUELGzIHT-I), GitHub, 51 minutes, 22 September 2025. Caveats: mechanics only; compiled from 2024 episodes.
- [Git and GitHub - Full Course](https://www.youtube.com/watch?v=rH3zE7VlIMs), ThePrimeagen for Boot.dev, 12 November 2024: remotes and GitHub from 1:54:18, then forks.
- The report found no verified video on roles, fork networks, releases or the API at this depth.

**Further reading**

- [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) and [best practices for organizations](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/best-practices-for-organizations).
- Chapter 18 for governance, Chapter 21B for fork networks during a secret leak, Chapter 27 for open-source practice.

# Module 19 labs: GitHub the platform

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 15](../textbook/ch15-github.md) first; each lab names the sections it uses. Answers to the questions are in [the solutions](../solutions/m19-lab-answers.md); write your own first.

## How these labs work

**These labs contact GitHub, so their GitHub steps run in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where macOS usually configures the credential helper, so it cannot authenticate to GitHub. The lab shell is used only where a step is marked "lab shell": those steps are local, and a replay script prints their real output.

What "Expected output" means here:

- For Git commands, it is the real output of a replay script in `labs/ch15/`, in which a bare repository on disk stands in for GitHub. Your commit IDs, name and email differ, because the replay uses the lab identity and a fixed clock.
- For `gh` commands and for anything GitHub displays, nothing could be run or captured while this book was written. The expected result is described from the linked documentation or from `gh <command> --help` of version 2.88.1, and the text says so. GitHub's interface changes: trust the page in front of you over the description.

You create the account, the organization and every credential yourself. No step asks you to paste a token into a command, a URL or a file.

Names used from here to the end of Level 5:

| Placeholder | Meaning |
|---|---|
| `YOUR-USER` | your GitHub user name |
| `YOUR-ORG` | your practice organization, created in Lab 19.1 |
| `practice-repo` | the practice repository, `YOUR-ORG/practice-repo` |
| `~/git-mastery/practice-repo` | your clone of it. Keep it outside the lab root, because setup scripts delete and rebuild their sandboxes |

The practice repository is **public**. Never push anything real to it: no secrets, no work code, no customer names.

## Lab 19.1: The practice organization and a repository with health files

### Objective

Create a free organization and a public repository with a README, a license, contributing and security files, two issue forms and a pull request template, and decide its settings on purpose. Be able to say what each step created in Git and what it created on GitHub.

### Prerequisites

Chapter 15, sections 15.3 to 15.5, 15.13 and 15.14. A GitHub account with two-factor authentication enabled. The GitHub CLI, logged in:

```bash
gh auth status
```

If it reports that you are not logged in, run `gh auth login`, choose `GitHub.com` and `HTTPS`, and let it authenticate Git with your GitHub credentials. Lab 20.2 takes apart what that did.

### Setup

Create the organization in the browser. GitHub's steps, from its documentation ([creating a new organization from scratch](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/creating-a-new-organization-from-scratch), read on 2 October 2026): click your profile picture, then **Settings**; in the "Access" section of the sidebar click **Organizations**; next to the "Organizations" header click **New organization**; follow the prompts and choose the free plan. Pick a name that is clearly yours and clearly practice.

Then copy the repository files. Run this from the course folder, in your normal shell:

```bash
mkdir -p ~/git-mastery
cp -R labs/ch15/practice-repo-template ~/git-mastery/practice-repo
cd ~/git-mastery/practice-repo
```

### Commands

```bash
# 1. Who you are locally. The email should be one that is verified on your GitHub account.
git config get user.name
git config get user.email
git config get init.defaultBranch          # expect: main. If empty: git config set --global init.defaultBranch main

# 2. The files
find . -type f | sort

# 3. A license. gh prints the text of a license template; read it, and fill in year and name where it asks.
gh repo license view MIT > LICENSE

# 4. A repository and a first commit
git init -b main
python3 -m unittest discover -s tests 2>&1 | tail -1
git status --short
git add .
git status --short
git commit -q -m "Add practice repository skeleton"
git log --oneline --stat --format="%h %an <%ae>%n   %s" | head -8

# 5. Create the repository in your organization and push
gh repo create YOUR-ORG/practice-repo --public --source=. --remote=origin --push \
  --description "Practice repository for the Git and GitHub mastery course"
git status -sb
git ls-remote origin

# 6. Settings, decided on purpose
gh repo edit YOUR-ORG/practice-repo --delete-branch-on-merge --enable-wiki=false --enable-projects=false
gh repo view YOUR-ORG/practice-repo --json nameWithOwner,visibility,defaultBranchRef,deleteBranchOnMerge,hasWikiEnabled,hasIssuesEnabled,licenseInfo,isSecurityPolicyEnabled

# 7. Look at the result in the browser
gh repo view --web
gh issue create --web                       # the template chooser; close the tab without creating an issue
```

In the browser, also open the community profile: under the repository name click **Insights**, then **Community Standards** in the left sidebar ([accessing a community profile](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/accessing-a-projects-community-profile)). And open your organization's settings and find the base permission: **Settings**, then **Member privileges** in the "Access" section of the sidebar, then "Base permissions" ([setting base permissions](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization)). Write down its value.

### Expected output

The Git steps, from the replay `labs/ch15/lab-19-1-practice-repo.sh`. It has no `LICENSE`, because that file comes from GitHub, and its push goes to a bare repository on disk.

<!-- snippet: ch15/lab-19-1-practice-repo/01-files -->
```text
$ cd practice-repo
$ find . -type f | sort
./.github/ISSUE_TEMPLATE/1-bug.yml
./.github/ISSUE_TEMPLATE/2-feature.yml
./.github/ISSUE_TEMPLATE/config.yml
./.github/pull_request_template.md
./.gitignore
./CONTRIBUTING.md
./docs/architecture.md
./pyproject.toml
./README.md
./SECURITY.md
./src/prompt_registry/__init__.py
./src/prompt_registry/registry.py
./tests/test_registry.py
```
<!-- /snippet -->

<!-- snippet: ch15/lab-19-1-practice-repo/02-init-and-check -->
```text
$ git init -b main
Initialized empty Git repository in $LAB/ch15/lab-19-1-practice-repo/practice-repo/.git/
$ git config get user.name; git config get user.email
Lab User
you@example.com
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ git status --short
?? .github/
?? .gitignore
?? CONTRIBUTING.md
?? README.md
?? SECURITY.md
?? docs/
?? pyproject.toml
?? src/
?? tests/
```
<!-- /snippet -->

<!-- snippet: ch15/lab-19-1-practice-repo/03-first-commit -->
```text
$ git add .
$ git status --short
A  .github/ISSUE_TEMPLATE/1-bug.yml
A  .github/ISSUE_TEMPLATE/2-feature.yml
A  .github/ISSUE_TEMPLATE/config.yml
A  .github/pull_request_template.md
A  .gitignore
A  CONTRIBUTING.md
A  README.md
A  SECURITY.md
A  docs/architecture.md
A  pyproject.toml
A  src/prompt_registry/__init__.py
A  src/prompt_registry/registry.py
A  tests/test_registry.py
$ git commit -q -m "Add practice repository skeleton"
$ git log --oneline --stat --format="%h %an <%ae>%n   %s" | head -8
49d8e88 Lab User <you@example.com>
   Add practice repository skeleton

 .github/ISSUE_TEMPLATE/1-bug.yml     | 29 +++++++++++++++++++++++++++++
 .github/ISSUE_TEMPLATE/2-feature.yml | 17 +++++++++++++++++
 .github/ISSUE_TEMPLATE/config.yml    |  1 +
 .github/pull_request_template.md     | 15 +++++++++++++++
 .gitignore                           | 17 +++++++++++++++++
```
<!-- /snippet -->

<!-- snippet: ch15/lab-19-1-practice-repo/04-push -->
```text
# Stand-in for: gh repo create YOUR-ORG/practice-repo --public --source=. --remote=origin --push
$ git remote add origin ../github-stand-in/practice-repo.git
$ git push -u origin main
To ../github-stand-in/practice-repo.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

Described, not captured:

- `gh repo license view MIT` prints the license text (`gh repo license view --help`).
- `gh repo create ... --source=. --remote=origin --push` creates the repository on GitHub, adds the remote `origin` to your local repository and pushes your commits. "Upon success" messages and the repository URL are printed; the wording is gh's and was not captured. Afterwards `git status -sb` and `git ls-remote origin` look like the transcript above, with your GitHub URL and your commit ID.
- `gh repo view --json ...` prints one JSON object with the fields you named. Expect a public visibility, the default branch `main`, `deleteBranchOnMerge` true, `hasWikiEnabled` false, the MIT license and `isSecurityPolicyEnabled` true. How gh renders each value was not captured.
- On the repository page GitHub renders `README.md`. The issue chooser offers "Bug report" and "Feature request" and no blank issue, except to people with Write, such as you ([issue template chooser](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository#configuring-the-template-chooser)).
- The community profile is a checklist of the health files; an issue form counts when it has valid `name` and `description` keys ([community profiles](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)).

### What happened internally

- **Git.** `git init -b main` created `.git` with an unborn branch `main`. The commit wrote blobs, trees and one commit object, and created `refs/heads/main`. Nothing else in this lab changed your Git data.
- **GitHub, at `gh repo create`.** A repository object was created in the organization with public visibility. `gh` then ran Git for you: it added the remote and pushed, which created `refs/heads/main` on the server and `refs/remotes/origin/main` in your clone. The name of a new repository's default branch comes from a setting of your account or organization, `main` unless someone changed it (the help text of `gh repo create` links the page), and you pushed a branch of that name.
- **GitHub, afterwards.** The settings you changed with `gh repo edit` are fields of the repository object. They are not in your clone and not in any commit.
- **The health files.** GitHub found `README.md`, `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md` and the files under `.github/` in the commit on the default branch and started using them. They are Git data that the platform interprets (Chapter 15, section 15.13).
- **The license.** `gh repo license view` made an API request and printed text. It became Git data when you committed the file.

### Checkpoint

```bash
git rev-parse HEAD
git ls-remote origin
git ls-files | wc -l | tr -d " "
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
```

<!-- snippet: ch15/lab-19-1-practice-repo/05-checkpoint -->
```text
$ git ls-remote origin
49d8e88de627d3ebbe1e6f00ebfc0446c1c506ea	HEAD
49d8e88de627d3ebbe1e6f00ebfc0446c1c506ea	refs/heads/main
$ git rev-parse HEAD
49d8e88de627d3ebbe1e6f00ebfc0446c1c506ea
$ git ls-files | wc -l | tr -d " "
13
```
<!-- /snippet -->

Your three commit IDs must be equal to each other (and different from the book's). You have 14 files, one more than the replay: the license. The last command prints `main`. If `git ls-remote` asks for a password or fails, stop here and do Lab 20.2 first.

### Failure scenario

Lab shell, local. The most common first-push failure: a repository whose first branch is not the one you push. Unconfigured Git 2.55 still names the first branch `master`.

```bash
labs/shell m19-1
git init -q --bare github-stand-in/scratch.git
git -c init.defaultBranch=master init -q scratch && cd scratch
git commit -q --allow-empty -m "First commit"
git remote add origin ../github-stand-in/scratch.git
git push -u origin main
git branch
```

<!-- snippet: ch15/lab-19-1-practice-repo/06-failure -->
```text
# A scratch repository created without the -b option, by a Git that has no init.defaultBranch:
$ cd ..
$ git init -q --bare github-stand-in/scratch.git
$ git -c init.defaultBranch=master init -q scratch && cd scratch
$ git commit -q --allow-empty -m "First commit"
$ git remote add origin ../github-stand-in/scratch.git
$ git push -u origin main
error: src refspec main does not match any
error: failed to push some refs to '../github-stand-in/scratch.git'
[exit status: 1]
$ git branch
* master
```
<!-- /snippet -->

`src refspec main does not match any` is Git saying that you have no local branch called `main`. Nothing was sent. The tempting way out, pushing `master` instead, leaves you with a repository whose branch is not called what its settings, its documentation and every later instruction expect.

### Recovery

```bash
git branch -m master main
git branch
git push -u origin main
```

<!-- snippet: ch15/lab-19-1-practice-repo/07-recovery -->
```text
$ git branch -m master main
$ git branch
* main
$ git push -u origin main
To ../github-stand-in/scratch.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```
<!-- /snippet -->

Rename the local branch before the first push, and set `init.defaultBranch` so that it does not happen again. Leave the lab shell with `exit`.

### Verification

Normal shell, in `~/git-mastery/practice-repo`:

```bash
git branch -vv
git ls-remote origin
gh repo view --json visibility,deleteBranchOnMerge
```

<!-- snippet: ch15/lab-19-1-practice-repo/08-verification -->
```text
$ cd ../practice-repo
$ git branch -vv
* main 49d8e88 [origin/main] Add practice repository skeleton
$ git ls-remote origin
49d8e88de627d3ebbe1e6f00ebfc0446c1c506ea	HEAD
49d8e88de627d3ebbe1e6f00ebfc0446c1c506ea	refs/heads/main
```
<!-- /snippet -->

One local branch tracking `origin/main`, and a server whose `HEAD` and `refs/heads/main` name your commit.

### Questions

1. List everything this lab created, in two columns: Git data and GitHub objects. In which column do the issue forms belong, and why is that the interesting answer?
2. `gh repo create --source=. --push` did three things. Name them, and say which Git commands would do the Git part.
3. Why did `main` become the default branch of the repository on GitHub? Who decided?
4. You enabled "delete branch on merge". Where is that setting stored, and which refs will it delete and not delete after a merge?
5. What is your organization's base permission, and what would a new member be able to do in `practice-repo` on their first day? What changes if the repository were private?
6. In the failure scenario, the error came from your own Git and not from the server. How can you tell from the text, and what had Git checked?
7. You filled in a year and a name in `LICENSE`. Where did the template come from, and at which moment did the license become part of the repository's history?

## Lab 19.2: An inventory of Git data and GitHub objects

### Objective

For one repository, list everything that is Git data and everything that is a GitHub object, and prove each classification with a command. Then lose the server and see what a mirror brings back.

### Prerequisites

Chapter 15, sections 15.2 and 15.7 to 15.12. Lab 19.1.

### Setup

Part A is local and runs in the lab shell:

```bash
bash labs/ch15/setup-19-2-inventory.sh
labs/shell m19-2
```

The sandbox has `server/practice-repo.git`, a bare repository that stands in for GitHub, with a feature branch pushed by Asha and an annotated tag, and your clone in `you/practice-repo`.

Part B runs in your normal shell, in `~/git-mastery/practice-repo`.

### Commands

Part A, lab shell:

```bash
# 1. Every ref the server has, and every ref your clone has
cd you/practice-repo
git ls-remote origin
git for-each-ref --format="%(objecttype) %(refname)"

# 2. Objects
git rev-list --all --objects | wc -l | tr -d " "
git cat-file -p v0.1.0

# 3. Platform configuration that is tracked files; a closing keyword that is text
git ls-files .github
git log -1 --format="%h %an%n%n%B" origin/feature/list-names

# 4. Local-only things
git config list --local --name-only
git reflog -2

# 5. A mirror
cd ../..
git clone --mirror server/practice-repo.git backup/practice-repo.git
git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
```

Part B, normal shell, against your real repository:

```bash
cd ~/git-mastery/practice-repo
git ls-remote origin

gh repo view --json nameWithOwner,visibility,isFork,parent,stargazerCount,watchers,defaultBranchRef
gh issue create --title "Inventory lab: a test issue" --body "Created in Lab 19.2." --label documentation
gh issue list
gh label list
gh release list
gh ruleset list
gh secret list
gh api repos/{owner}/{repo} --jq '{full_name, private, default_branch, has_issues, has_wiki, permissions}'
```

Now fill in this table on paper. For each row write the layer, the command that showed it, and whether a `git clone --mirror` would carry it.

| Thing | Git data or GitHub object? | Command that proves it | In a mirror? |
|---|---|---|---|
| the commit on `main` | | | |
| the branch `main` on the server | | | |
| `origin/main` in your clone | | | |
| an annotated tag | | | |
| the issue forms | | | |
| the issue you created | | | |
| the label `documentation` | | | |
| the repository's visibility | | | |
| "delete branch on merge" | | | |
| your role on the repository | | | |
| the reflog of your clone | | | |
| a star someone gives the repository | | | |

### Expected output

Part A, from the replay `labs/ch15/lab-19-2-inventory.sh`:

<!-- snippet: ch15/lab-19-2-inventory/01-refs -->
```text
$ cd you/practice-repo
$ git ls-remote origin
bf7889c1f62437e0b230c6660eafdf164e53abb3	HEAD
c130f61d1e57e67200e2515c5025816e16f669e1	refs/heads/feature/list-names
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/heads/main
52358fb1173bb4c30186312ad769d3415d31e71c	refs/tags/v0.1.0
bf7889c1f62437e0b230c6660eafdf164e53abb3	refs/tags/v0.1.0^{}
$ git for-each-ref --format="%(objecttype) %(refname)"
commit refs/heads/main
commit refs/remotes/origin/HEAD
commit refs/remotes/origin/feature/list-names
commit refs/remotes/origin/main
tag refs/tags/v0.1.0
```
<!-- /snippet -->

<!-- snippet: ch15/lab-19-2-inventory/02-objects -->
```text
$ git rev-list --all --objects | wc -l | tr -d " "
33
$ git cat-file -p v0.1.0
object bf7889c1f62437e0b230c6660eafdf164e53abb3
type commit
tag v0.1.0
tagger Asha Rao <asha@example.com> 1788756000 +0530

practice-repo 0.1.0
```
<!-- /snippet -->

<!-- snippet: ch15/lab-19-2-inventory/03-tracked-platform-files -->
```text
$ git ls-files .github
.github/ISSUE_TEMPLATE/1-bug.yml
.github/ISSUE_TEMPLATE/2-feature.yml
.github/ISSUE_TEMPLATE/config.yml
.github/pull_request_template.md
$ git log -1 --format="%h %an%n%n%B" origin/feature/list-names
c130f61 Asha Rao

Add names() to list registered prompts

Fixes #12
```
<!-- /snippet -->

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

<!-- snippet: ch15/lab-19-2-inventory/05-mirror -->
```text
$ cd ../..
$ git clone --mirror server/practice-repo.git backup/practice-repo.git
Cloning into bare repository 'backup/practice-repo.git'...
done.
$ git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
commit refs/heads/feature/list-names
commit refs/heads/main
tag refs/tags/v0.1.0
```
<!-- /snippet -->

Part B, described and not captured. `git ls-remote origin` lists `HEAD` and `refs/heads/main`; once the repository has pull requests it also lists `refs/pull/N/head` lines (Chapter 17). `gh issue create` prints the URL of the new issue. `gh issue list` and `gh label list` print tables; the label list contains GitHub's default labels ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)). `gh release list`, `gh ruleset list` and `gh secret list` have nothing to show yet and say so in gh's own words. The `gh api` call prints one JSON object with the six fields; `permissions` shows what your token may do in this repository. Field names are from the REST reference ([get a repository](https://docs.github.com/en/rest/repos/repos#get-a-repository)).

### What happened internally

- A clone asked the server for `refs/heads/*` and tags and received the objects those refs reach. The server's branches became remote-tracking branches; one local branch was created.
- The tag `v0.1.0` is a tag object with a tagger and a message, pointing at a commit. It travelled because tags that point into fetched history are followed.
- The issue forms and the pull request template are blobs in the tree of a commit. The words `Fixes #12` are bytes in a commit object.
- Your clone's configuration and reflog were created locally by `git clone`. No server ever held them.
- The mirror used the refspec `+refs/*:refs/*`: every ref, same names, no remote-tracking namespace.
- In Part B, every `gh` command made API requests with your token. The issue, the labels and the settings exist only in GitHub's database. Creating the issue changed no Git object: `git ls-remote origin` prints the same lines before and after.

### Checkpoint

Lab shell:

```bash
git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
git -C server/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
```

<!-- snippet: ch15/lab-19-2-inventory/06-checkpoint -->
```text
$ git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
33
$ git -C server/practice-repo.git rev-list --all --objects | wc -l | tr -d " "
33
```
<!-- /snippet -->

The mirror holds exactly the objects the server holds. If your table has "yes" in the mirror column for anything that is not a ref or an object, reread section 15.2.

### Failure scenario

Lab shell. The server is lost: deleted by mistake, or your organization lost access to it.

```bash
rm -rf server/practice-repo.git
git -C you/practice-repo fetch origin
```

<!-- snippet: ch15/lab-19-2-inventory/07-failure -->
```text
# The server is gone: deleted by mistake, or the organization lost access.
$ rm -rf server/practice-repo.git
$ git -C you/practice-repo fetch origin
fatal: '../../server/practice-repo.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

### Recovery

```bash
git init -q --bare server/practice-repo.git
git -C backup/practice-repo.git push --mirror ../../server/practice-repo.git
git -C you/practice-repo fetch origin
```

<!-- snippet: ch15/lab-19-2-inventory/08-recovery -->
```text
$ git init -q --bare server/practice-repo.git
$ git -C backup/practice-repo.git push --mirror ../../server/practice-repo.git
To ../../server/practice-repo.git
 * [new branch]      feature/list-names -> feature/list-names
 * [new branch]      main -> main
 * [new tag]         v0.1.0 -> v0.1.0
$ git -C you/practice-repo fetch origin
```
<!-- /snippet -->

Every ref and object is back, and your clone noticed nothing. On GitHub the same recovery would restore the same things and nothing more. The issue of Part B, the labels, the settings of Lab 19.1 and the organization's roles would have to come from an export made through the API before the loss, or from GitHub: a deleted repository can be restored within 90 days unless its fork network is not empty ([restoring a deleted repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/restoring-a-deleted-repository)).

🔴 `git push --mirror` makes the destination's refs equal to the source's, deleting refs that the source lacks. It was right here because the destination was empty.

### Verification

```bash
git -C server/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
git -C you/practice-repo status -sb
```

<!-- snippet: ch15/lab-19-2-inventory/09-verification -->
```text
$ git -C server/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"
commit refs/heads/feature/list-names
commit refs/heads/main
tag refs/tags/v0.1.0
$ git -C you/practice-repo status -sb
## main...origin/main
```
<!-- /snippet -->

Leave the lab shell. In your normal shell, close the test issue: `gh issue close N --reason "not planned"` with the number that `gh issue list` showed.

### Questions

1. Your clone has `refs/remotes/origin/main` and the mirror has `refs/heads/main` for the same commit. Explain the difference from the refspecs.
2. `Fixes #12` was in a commit message in a sandbox with no issue tracker. What would GitHub do with that commit if it reached the default branch of your practice repository, and what if issue 12 does not exist there?
3. Creating the issue in Part B did not change the output of `git ls-remote origin`. What would have changed it?
4. After the recovery in the lab shell, which of these would be missing if the server had been GitHub: tags, open pull requests, the default branch setting, release notes, the `.github` directory, deploy keys?
5. Name two things in the inventory that are in neither a mirror nor GitHub's database.
6. A colleague proposes a nightly `git clone --mirror` as "the backup of our GitHub organization". Write the two-sentence answer you would give.

# Exercises, Modules 19 to 25: GitHub

> **Baseline.** Git 2.55.0, OpenSSH 10.2 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Every transcript in this file is real output of a script in `labs/ex3/`. Nothing here was run against GitHub. Where an exercise describes what GitHub does, the description follows the textbook chapter named in the exercise, and GitHub's interface changes: trust the page in front of you over a description.

## How to use these exercises

Do the labs of a module first; these exercises practise the same chapters in other situations. Write your answer before you open [the solutions](../solutions/exercises-m19-m25.md). This file contains no answers.

**Levels.** Level 1: instructions to follow. Level 2: a goal and limited hints. Level 3: a situation to diagnose on your own. Level 4: symptoms only, in a repository that a script builds for you. Level 5: a production incident with incomplete and partly misleading evidence; you must find the root cause and choose the lowest-risk fix.

**Four kinds of exercise.**

| Kind | Where you work | How you know you are right |
|---|---|---|
| Do it on GitHub | your normal shell, in your clone of `YOUR-ORG/practice-repo` | the self-check list in the exercise |
| Read and diagnose | on paper | the solution, which cites the textbook section |
| Local simulation | the lab shell (`labs/shell`), where a bare repository on disk plays GitHub | a real transcript in the solution |
| Design | on paper | the rubric in the solution |

**GitHub steps run in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub. Replace `YOUR-USER` and `YOUR-ORG` with your account and your practice organization.

**Local simulations.** Exercises 20.6, 21.6 and 22.5 have a setup script. Run it from the course root, open the lab shell where it tells you, and work from the symptoms. Running the setup script again gives you a fresh copy. The other local exercises ask you to predict; the solution holds the transcript, and `labs/run ex3/<name>` replays it on your machine.

**Secrets.** No exercise needs a real secret. Never paste a token into a command line, a file or a chat.

---

## Module 19: GitHub the platform

Chapter: [15, GitHub](../textbook/ch15-github.md).

### Exercise 19.1 (Level 1, read and diagnose): Git data or GitHub object?

For each item, write three things: the layer (Git data, Git data that GitHub interprets, or a GitHub object), one command that reads it, and whether `git clone` brings it to your machine.

1. The annotated tag `v1.2.0`
2. The release notes of release v1.2.0
3. `.github/CODEOWNERS`
4. An approving review on pull request 7
5. `refs/pull/7/head`
6. The setting that says which branch is the default branch
7. The words `Fixes #41` in a commit message
8. A star on the repository
9. The Actions secret `STAGING_DEPLOY_KEY`
10. The repository's wiki
11. The ruleset that protects `main`
12. A deploy key

Then answer in two sentences: your company moves this repository to another host with `git clone --mirror` and `git push --mirror`. Which of the twelve arrive, and what do you have to plan for the rest?

### Exercise 19.2 (Level 1, do it on GitHub): Settings on purpose

In your clone of `YOUR-ORG/practice-repo`, in your normal shell:

```bash
gh repo view --json                      # prints the field names you may ask for
gh repo view --json defaultBranchRef,visibility
gh repo edit --delete-branch-on-merge
gh repo edit --enable-wiki=false
gh repo edit --enable-merge-commit=false --enable-squash-merge --enable-rebase-merge=false
gh repo view --json deleteBranchOnMerge,hasWikiEnabled,mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed
```

Before each `gh repo edit`, say aloud what GitHub object changes and whether anything in your clone changes. After the third edit, write down what the merge box of a pull request will offer.

Self-check:

- [ ] You can name the JSON field that holds the default branch without looking.
- [ ] You can explain why none of the three edits shows up in `git status`, `git log` or `git config list`.
- [ ] You can say what a teammate must still run in their clone after a pull request merges and its head branch is deleted on the server.
- [ ] You know which of these settings a `git push --mirror` to a new host would carry over.

### Exercise 19.3 (Level 2, read and diagnose): Effective access

The organization `northwind-ml` has the base permission **Read**. It has three private repositories: `chunker`, `ranker-service` and `billing-export`.

| Grant | Details |
|---|---|
| Team `ml-platform` | Write on `chunker` |
| Team `ml-eval`, a child team of `ml-platform` | Triage on `ranker-service` |
| Direct grant | Meera: Maintain on `ranker-service` |
| Outside collaborator | Tariq: Write on `chunker` |
| Organization owner | Dana |

Meera is a member of `ml-eval` only. Jonas is a member of `ml-platform` only.

1. Fill in the effective role of Meera, Jonas, Tariq and Dana on each of the three repositories.
2. Who can create an Actions secret in `chunker`?
3. Whose approval counts toward a required review in `ranker-service`?
4. Who can change a ruleset of `chunker`?
5. Tariq's contract ends and he is removed as outside collaborator. Name one credential that could still give him access, and where you would look for it.
6. The CTO wants contractors to see only the repositories they are added to. What do you change, and what does that change do to Jonas?

### Exercise 19.4 (Level 2, local simulation): What a clone receives, and where a keyword travels

A bare repository plays the platform. Its default branch is `main`, and it has a branch `release/1.2`. You made this commit on a branch `fix/empty-doc`, cut from `release/1.2`:

<!-- snippet: ex3/x19-keyword-and-refs/01-the-commit -->
```text
$ git log -1 --format="%h %s%n%n%b" fix/empty-doc
24b1d51 Return no chunks for empty text

Fixes #41
```
<!-- /snippet -->

Then, in this order:

1. You opened pull request 7 from `fix/empty-doc` into `release/1.2`. Its description also says `Fixes #41`.
2. Asha merged pull request 7 with a merge commit.
3. Asha ran `git cherry-pick` of your commit on `main` and pushed `main`.
4. Asha deleted the branch `fix/empty-doc` on the server.

Somebody now clones the repository for the first time. Predict:

- a. Which refs does `git for-each-ref` list in the fresh clone?
- b. How many lines does `git ls-remote origin` print, and which of them names something the clone did not receive as a ref?
- c. How many commits does `git log --all --grep="Fixes #41"` list in the fresh clone, and on which branches are they?
- d. After `git fetch origin pull/7/head:pr-7`, which branches does `git branch -a --contains pr-7` list?
- e. On GitHub, at which of the four steps does issue 41 close? Give the documented rule for each step that does not close it.

### Exercise 19.5 (Level 3, read and diagnose): The fork that was deleted

Your repository `northwind-ml/chunker` is public. An intern forked it, pushed a branch `debug/staging` to her fork with a commit that contains a staging database password, noticed within the hour, deleted the branch, and then deleted the fork. She has the commit ID in her terminal scrollback.

A colleague writes in the incident channel: "Nothing to do. It was never in our repository, the branch is gone and the fork is gone."

1. Is the commit still obtainable? Through which repository, and what does somebody need to know to get it?
2. Which statement in GitHub's documentation decides this? Name the chapter section.
3. Put these four actions in the right order and say which one makes the password harmless: ask GitHub Support to remove the commit; rotate the password; make `northwind-ml/chunker` private; write the postmortem.
4. What would making the repository private change, and what would it leave as it is?
5. Which two controls would have stopped the push or made it harmless?

### Exercise 19.6 (Level 2, read and diagnose): Health files and the issue chooser

The default branch of a repository contains these files:

```text
CONTRIBUTING.md
docs/CONTRIBUTING.md
.github/CONTRIBUTING.md
.github/ISSUE_TEMPLATE/config.yml        (contains: blank_issues_enabled: false)
.github/ISSUE_TEMPLATE/bug.yml
LICENSE
```

A branch `forms/feature-request`, not yet merged, adds `.github/ISSUE_TEMPLATE/feature.yml`.

1. Which of the three `CONTRIBUTING.md` files does GitHub link when somebody opens an issue? State the search order.
2. A user with the Read role opens the "new issue" page. What do they see? What does a user with the Write role see in addition?
3. The author of `feature.yml` reports that the form does not appear in the chooser. Give the two documented reasons a form can be missing, and say which one applies here.
4. The organization also has a public repository named `.github` with a `SECURITY.md`. This repository has none. What happens, and which file would the `.github` repository not supply?

### Exercise 19.7 (Level 5, production incident): "We made it private, so we are fine"

You are asked to review this timeline from another team. Decide what is true, what is irrelevant, and what must happen now.

- Monday 09:10. A contractor reports that commit `c41d` (abbreviated here on purpose) on `main` of the public repository `northwind-ml/ranker-service` contains a cloud storage key. It was pushed three weeks ago.
- 09:25. An administrator changes the repository's visibility to private.
- 09:40. The administrator commits a deletion of the file and pushes it.
- 10:00. The team lead reports: "Contained. The repository is private and the file is gone."
- 10:30. Marketing complains that the repository's star count dropped from several hundred to zero and suspects a compromise.
- 11:00. Someone notices that two public forks of the repository still exist under other accounts.
- 11:15. Someone else notes that the nightly export still works, although the engineer who set it up left in June. It uses a deploy key.
- 11:30. The key has not been rotated, "because it is no longer reachable".

1. Which single fact decides whether the incident is contained? What is its current state?
2. Explain the zero stars. Is it evidence of compromise?
3. What is the status of the two forks, and what can their owners still read?
4. Is the deploy key part of this incident? Is it a finding?
5. Write the three-line message you would send to the CTO: what happened, what is being done in the next hour, and what will prevent it.

---

## Module 20: Authentication and SSH

Chapter: [16, Authentication](../textbook/ch16-authentication.md). The error texts below are the ones the chapter quotes; the listings are real output from a sandbox in which nothing connects to GitHub.

### Exercise 20.1 (Level 1, read and diagnose): Who wrote this line?

For each line, name the program that wrote it (your `ssh` client, GitHub's server, or Git), and say which of the chapter's three questions it answers: which transport and server, which credential the client presented, or who the server says you are and what that identity may do.

1. `Permission denied (publickey)`
2. `fatal: Could not read from remote repository.`
3. `Host key verification failed.`
4. `fatal: Authentication failed for 'https://github.com/northwind-ml/chunker.git/'`
5. `fatal: could not read Username for 'https://github.com': terminal prompts disabled`
6. `Permission to northwind-ml/chunker denied to` followed by a user name
7. `ERROR: We're doing an SSH key audit.`

Then: a ticket quotes only line 2. Write the one sentence you send back.

### Exercise 20.2 (Level 2, read and diagnose): Pick the credential

For each job, name the credential type you would use, its lifetime, what a thief could reach with it, and one credential that looks convenient and is the wrong choice.

1. A nightly job on a company server that reads three private repositories of one organization and opens pull requests in them.
2. `docker login ghcr.io` on your laptop, to pull a private image.
3. Your own contributions, over HTTPS, to an open-source repository in which you are not a member.
4. A workflow in `inventory-api` that comments on pull requests of `inventory-api`.
5. A production server that needs to `git pull` exactly one private repository, read-only.

### Exercise 20.3 (Level 3, read and diagnose): 403, and Git never asks

Ravi was given the Write role on `northwind-ml/eval-reports` two days ago, on his work account. `git push` fails every time with a line that ends in `The requested URL returned error: 403`. Git never prompts him for anything. He has reinstalled the GitHub CLI once. This is his machine:

<!-- snippet: ex3/x20-auth-evidence/a-evidence -->
```text
$ git remote -v
origin	https://github.com/northwind-ml/eval-reports.git (fetch)
origin	https://github.com/northwind-ml/eval-reports.git (push)
$ git config get --show-origin --all credential.helper
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig	personalstore
$ git config get --show-origin --all credential.https://github.com.helper
file:$LAB/ex3/x20-auth-evidence/home/.gitconfig	workstore
```
<!-- /snippet -->

`personalstore` and `workstore` are two helpers; each holds the credential of one of his two accounts.

1. Which helper answers for `github.com`, and why? Name the rule.
2. Why does Git never prompt, and why did granting access change nothing?
3. Which two commands, neither of which changes anything, would you run to confirm your answer?
4. Write the configuration change that repairs it. What must the first value of the per-host list be?
5. Which line of the error would have been different if the stored credential had been revoked instead of belonging to the other account, and what would Git have done to the stored credential?

### Exercise 20.4 (Level 3, read and diagnose): `Permission denied (publickey)`

On a new laptop, `git fetch` in `~/work/chunker` fails with `Permission denied (publickey)`, followed by Git's `fatal: Could not read from remote repository.` Your public key is on your GitHub account; you checked in the browser. This is the laptop:

<!-- snippet: ex3/x20-auth-evidence/b-evidence -->
```text
$ git remote -v
origin	git@github.com:northwind-ml/chunker.git (fetch)
origin	git@github.com:northwind-ml/chunker.git (push)
$ ssh -T -F ~/.ssh/config -G github.com | grep -E '^(hostname|user|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_ed25519_work
$ ls ~/.ssh
config
id_ed25519
id_ed25519.pub
known_hosts
```
<!-- /snippet -->

(`-F` names the sandbox file; on your own machine you omit it.)

1. What does this error say about your permission on the repository `northwind-ml/chunker`?
2. Find the root cause in the listing. Which two lines produce it together?
3. Which command shows what the client offered to the server, and what do you expect to read there?
4. Give two different repairs and say when each is the right one.
5. A colleague suggests `sudo git fetch`. What changes under `sudo`, and why does it not help?

### Exercise 20.5 (Level 3, read and diagnose): The push works, the address is wrong

You have a personal and a work account on one machine. Pushes to `northwind-ml/ranker-service` succeed, authenticated as the work account. Your manager points out that your commits there carry your personal address. This is the configuration and the repository:

<!-- snippet: ex3/x20-auth-evidence/c-evidence -->
```text
$ cat ~/.gitconfig
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
[user]
	name = Lab User
	email = lab-user@personal.example
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
$ cat ~/.gitconfig-work
[user]
	email = lab.user@northwind.example
[url "git@github-work:"]
	insteadOf = git@github.com:
$ git config get remote.origin.url
git@github.com:northwind-ml/ranker-service.git
$ git remote get-url origin
git@github-work:northwind-ml/ranker-service.git
$ git log -1 --format='%an <%ae>  %s'
Lab User <lab-user@personal.example>  Add README
```
<!-- /snippet -->

1. The include is applied: the URL is rewritten. Why does the email not follow?
2. Which command shows every value of `user.email` with the file it comes from, and in which order do you expect them?
3. Name the three identities of section 16.2 and say which of them is wrong here and which are right.
4. Repair the configuration. Then say what you do about the commits that are already pushed, and what you do not do.

### Exercise 20.6 (Level 4, local simulation): Three faults, no connection

```bash
bash labs/ex3/setup-x20-6-three-faults.sh
labs/shell x20-6
export HOME="$PWD/home" GIT_CONFIG_GLOBAL="$PWD/home/.gitconfig"     # first command in that shell
cd ~/work/chunker
```

The `export` keeps `~` and `git config --global` inside the sandbox. `ssh` does not use `$HOME` to find its files, so pass `-F ~/.ssh/config` to every `ssh` command. Do not connect anywhere: `ssh -G` prints the configuration a connection would use and exits.

Symptoms, as reported by the owner of this home directory:

- "`git fetch` in `~/work/chunker` fails with `Permission denied (publickey)`. My work key is on my work account; I checked in the browser."
- "My last commit in this repository shows my personal address."
- "I set this machine up from our two-account guide: a work alias in `~/.ssh/config`, and an include for everything under `~/work`."

There are three faults. Repairing any one of them alone does not make the fetch work, and after some partial repairs the error text would change. Find all three without connecting, repair them, and prove the repair with commands that print configuration.

Self-check:

- [ ] `git remote get-url origin` prints a URL that goes through the work alias, and `git config get remote.origin.url` still prints the canonical URL.
- [ ] `git config get user.email` prints the work address inside `~/work/chunker`.
- [ ] `ssh -F ~/.ssh/config -G github-work` shows the user that GitHub requires, and its first identity file exists in `~/.ssh`.
- [ ] You can say which error the owner would have met after repairing only the order of the blocks in `~/.ssh/config`, and who would have written that line.
- [ ] You changed nothing outside the sandbox.

### Exercise 20.7 (Level 5, production incident): The nightly sync says "not found"

Since Thursday, the nightly job that mirrors `northwind-ml/feature-store` to an internal analytics host fails. The job log ends with a `remote:` line that says `Repository not found`, followed by Git's `fatal: repository 'https://github.com/northwind-ml/feature-store.git/' not found`. Evidence collected so far:

- The repository exists; three engineers have it open in their browsers.
- The repository was renamed from `features` to `feature-store` in August. The job's URL already uses the new name.
- The job authenticates over HTTPS with a personal access token (classic) that its script reads from a file. The file was last changed in March 2025.
- The file was written by an engineer who moved to another company in June. Her account was removed from the organization last Wednesday in an access review.
- A teammate reran the job by hand from his laptop "and it worked", then concluded that the analytics host has a network problem.
- GitHub's status page shows no incident.

1. State the root cause in one sentence, and name the single piece of evidence that carries it.
2. Why does the server say "not found" for a repository that exists? Which section explains the choice of status code?
3. Explain away the three pieces of misleading evidence: the rename, the laptop rerun, the status page.
4. What is the lowest-risk repair for tonight, and what is the right repair for next week? Say what each one authenticates as.
5. Which finding goes into the postmortem that has nothing to do with the failure itself?

### Exercise 20.8 (Level 2, read and diagnose): The SSH calendar

GitHub announced SSH changes for 14 October 2026 and 13 January 2027. For each machine, say whether it is affected, by which date, and what you would run to check.

| Machine | Client | Key in use |
|---|---|---|
| A. Your laptop | OpenSSH 10.2 | RSA, 2048 bits, uploaded in 2019 |
| B. An old build agent | OpenSSH 6.6 | RSA, 4096 bits, uploaded in 2016 |
| C. A new hire's laptop, set up on 20 October 2026 | OpenSSH 10.2 | wants to create and upload an RSA 2048-bit key |
| D. A data-collection appliance | OpenSSH 8.9 | Ed25519 |
| E. A reporting script | uses an `https://` remote and a token | none |

Then: one statement in this area is marked unverified in the chapter. Which one, and how does it change what you tell the owner of machine A?

---

## Module 21: Pull requests, review, and the fork workflow

Chapter: [17, Pull requests](../textbook/ch17-pull-requests.md), sections 17.1 to 17.7 and 17.12 to 17.17.

### Exercise 21.1 (Level 1, do it on GitHub): A draft, a range, and the head ref

In your clone of `YOUR-ORG/practice-repo`, in your normal shell. Use a branch with one small commit; a change to the README is enough.

```bash
git switch -c docs/exercise-21-1
# edit README.md, then:
git commit -am "Describe how to run the tests"
git fetch
git log --oneline origin/main..HEAD            # what the Commits tab will list
git diff --stat origin/main...HEAD             # what the Files changed tab will show
git push -u origin docs/exercise-21-1
gh pr create --draft --fill
gh pr view --json number,isDraft,baseRefName,headRefOid
git ls-remote origin 'refs/pull/*'
gh pr ready
```

Then fetch the pull request's head with plain Git into a branch named `pr-check`, using the number that `gh pr view` printed, and compare it with your branch. Close the pull request without merging and delete the branch when you are done (`gh pr close --delete-branch`).

Self-check:

- [ ] Before `gh pr create`, you could say how many commits and files the page would show.
- [ ] You can say which of the commands above created Git data on the server and which created a GitHub object.
- [ ] `git rev-parse pr-check` and `git rev-parse docs/exercise-21-1` print the same ID, and you can explain why `git fetch` alone never gave you that ref.
- [ ] You can say what a draft changes for code owners and for the merge button.
- [ ] After you closed the pull request and deleted the branch, you can say whether the commit is still on the server, and under which name.

### Exercise 21.2 (Level 2, read and diagnose): Is it still approved?

A ruleset on `main` requires one approval. Consider this sequence on one pull request, whose author has the Write role:

1. Reviewer R approves.
2. The author pushes one more commit.
3. Reviewer S approves.
4. Somebody clicks **Update branch**.
5. Another pull request merges into `main`; it changes a file that this pull request also changes, without a conflict.
6. Reviewer S pushes a small fix to the branch and approves again.

Answer for two configurations. A: "dismiss stale approvals" is on. B: "require approval of the most recent reviewable push" is on, and dismissal is off.

1. Under A, after each of the six steps: does the pull request have a standing approval?
2. Under B: after step 2, whose approval is needed? After step 6, is the approval that S has just given enough?
3. Which configuration does GitHub's documentation call safer, and what does the other one buy?
4. With neither option set, after which step has an unreviewed commit become mergeable?
5. Step 5 touches nobody's branch. Under A, can an event like it cost a pull request its approval? Quote the rule.

### Exercise 21.3 (Level 2, local simulation): A stack, and a squash underneath it

You have two branches. `feature/overlap` has two commits. `feature/overlap-tests` was created on top of it and adds one commit. `main` has moved by one commit since you branched. After `git fetch`:

<!-- snippet: ex3/x21-stack-predict/01-graph -->
```text
$ git log --graph --oneline --all
* dad6e83 Double the default chunk size
| * acbec10 Test that overlap repeats characters
| * 281f566 Reject an overlap that is not smaller than the size
| * 5b7fd29 Add overlap parameter
|/  
* 6258ae5 Add splitter test
* e636524 Add chunking config
* 81ee9da Add fixed-size splitter
* 94d97ae Add README
```
<!-- /snippet -->

`dad6e83` changes `config/chunking.yaml`. The two lower commits change `chunker/split.py`. `acbec10` changes `tests/test_split.py`.

Part 1. Predict, for a pull request with head `feature/overlap-tests`:

- a. How many commits does it list with base `main`? With base `feature/overlap`?
- b. Which files does `git diff --stat origin/main...feature/overlap-tests` name? Which additional file does the two-dot form name, and what does its diff claim?

Part 2. Asha squash-merges the pull request for `feature/overlap` into `main` and deletes that branch on the server. GitHub retargets your upper pull request to `main`. You run `git fetch --prune`; your local branch `feature/overlap` still exists. Predict:

- c. What does `git merge-base origin/main feature/overlap-tests` name now: the squash commit, `dad6e83`, or `6258ae5`?
- d. How many commits does the upper pull request list now, and how many files does it show?
- e. Does the test merge of `feature/overlap-tests` into `main` conflict? Both sides changed `chunker/split.py` since the merge base. Give the reason for your answer.
- f. Write the one command that leaves the branch with exactly its own commit on top of `main`. What kind of push does it need afterwards?

### Exercise 21.4 (Level 3, read and diagnose): Three small mysteries

Each has one documented cause. Name it and the section.

1. A pull request has been open for a day. It has no workflow run at all, although the repository's CI workflow triggers on `pull_request` without filters, and other pull requests get runs. It is not a draft.
2. A reviewer chose **Request changes**. An hour later the author merged the pull request anyway. No administrator was involved and nobody dismissed the review.
3. A script closes pull requests that "cannot be merged". It closed a pull request two seconds after it was opened; the pull request had no conflict. The script reads one field of the REST response for the pull request.

### Exercise 21.5 (Level 3, read and diagnose): The fork that cannot be synced

A contributor works in a clone whose `origin` is their fork and whose `upstream` is the shared repository. After `git fetch --all`, this command prints two numbers, `3` and `2`, in that order:

```bash
git rev-list --left-right --count upstream/main...origin/main
```

1. What does each number mean?
2. The contributor says: "I only ever worked on feature branches." Which habit most likely produced the second number?
3. What would `gh repo sync YOUR-USER/chunker` do in this state, and what would it do with `--force`? What is destroyed in the second case, and where could it be recovered from?
4. Write the sequence of Git commands that keeps the contributor's work and brings the fork's `main` in line with upstream. Label each state-changing command with its risk.
5. State the three rules that prevent this.

### Exercise 21.6 (Level 4, local simulation): Five commits for a two-commit fix

```bash
bash labs/ex3/setup-x21-6-foreign-commits.sh
labs/shell x21-6/you/chunker
```

You are in your clone, on your branch `fix/unicode-split`. A bare repository beside it plays GitHub. Pull request 23, from your branch into `main`, is open.

Symptoms:

- The pull request page lists five commits and five files. You wrote two commits, which touch two files.
- Ravi, a teammate, comments on the pull request: "Why is my WIP commit in your pull request? I squashed that away yesterday."
- You have not fetched since you pushed.

Find out which commits are yours, where the others came from, and why they are not recognizable as Ravi's current branch. Repair your branch so that the pull request contains exactly your work, verify it before you publish, and publish it with the safest push that works.

Self-check:

- [ ] `git log --oneline origin/main..HEAD` lists exactly your two commits.
- [ ] `git diff --stat origin/main...HEAD` names exactly two files.
- [ ] You checked that the test merge into `origin/main` is clean before pushing.
- [ ] You can explain why changing the base of the pull request would not have been a repair here.
- [ ] You can say which commits Ravi's rewrite left on the server, and under which ref of yours they were still reachable.
- [ ] You did not touch Ravi's branch.

### Exercise 21.7 (Level 5, production incident): Green on the pull request, red on main

`main` of `inventory-api` deploys on every merge. At 14:10 the deployment workflow on `main` failed in the test job: `test_reserve_rejects_negative_quantity` raised a `TypeError`. Evidence:

- Pull request 310 (rename the parameter `qty` to `quantity` in `reserve()`) merged at 13:52. Its checks were green; they had run the previous evening at 18:40.
- Pull request 312 (add a call to `reserve(qty=...)` in a new module, with a test) merged at 14:08. Its checks were green; they had run at 11:15.
- Neither pull request had a merge conflict, at any time.
- The ruleset on `main` requires the check `ci`. "Require branches to be up to date before merging" is not selected.
- A senior engineer says the test is flaky: "It failed twice last month for no reason."
- Someone proposes re-running the failed job until it passes.

1. What did CI test for pull request 312 at 11:15? Name the commit in terms of its two parents.
2. State the root cause in one sentence. Why did Git report no conflict?
3. Deal with the "flaky test" theory using evidence you could collect in two commands on a clone.
4. What is the lowest-risk action for the next ten minutes? Give the alternative and say why you rank it second.
5. Name two platform controls that would have prevented this, with the cost of each, and say which one fits a repository with a few merges a day.

---

## Module 22: Merge methods, merge queue, and releases on GitHub

Chapters: [17](../textbook/ch17-pull-requests.md), sections 17.8 to 17.11, and [15](../textbook/ch15-github.md), section 15.12.

### Exercise 22.1 (Level 1, read and diagnose): The three buttons from memory

Without the book, fill in the table. Then check it against section 17.8.

| | Create a merge commit | Squash and merge | Rebase and merge |
|---|---|---|---|
| New commits on the base | | | |
| Are your original commit IDs on the base afterwards? | | | |
| Who is the committer of what lands? | | | |
| Is what lands signed, and by whom? | | | |
| Allowed under "Require linear history"? | | | |
| What is lost, according to the documentation? | | | |

One row has an entry that the documentation does not state and the chapter marks unverified. Which?

### Exercise 22.2 (Level 2, local simulation): Which button was pressed?

One pull request, `feature/overlap` into `main`, with these three commits (newest first):

<!-- snippet: ex3/x22-which-method/01-pull-request -->
```text
# The pull request: feature/overlap into main. Its head commit and its commits:
$ git -C you/chunker log --format='%h | %an | %s' main..feature/overlap
39301d4 | Lab User | Reject an overlap that is not smaller than the size
8743f96 | Lab User | Test that overlap repeats characters
5b7fd29 | Lab User | Add overlap parameter
```
<!-- /snippet -->

It was merged three times, in three copies X, Y and Z of the same repository, with the three local commands that correspond to the three buttons. Asha did the merging. The columns are commit, author, committer, subject.

<!-- snippet: ex3/x22-which-method/02-history-x -->
```text
$ git -C X log --graph --format='%h | %an | %cn | %s' -5 main
* 3fa8f65 | Lab User | Asha Rao | Reject an overlap that is not smaller than the size
* 06504a8 | Lab User | Asha Rao | Test that overlap repeats characters
* bd5dffa | Lab User | Asha Rao | Add overlap parameter
* 1b220ee | Asha Rao | Asha Rao | Double the default chunk size
* 6258ae5 | Asha Rao | Asha Rao | Add splitter test
```
<!-- /snippet -->

<!-- snippet: ex3/x22-which-method/03-history-y -->
```text
$ git -C Y log --graph --format='%h | %an | %cn | %s' -5 main
* 461e56e | Asha Rao | Asha Rao | Add overlap to the splitter (#12)
* 1b220ee | Asha Rao | Asha Rao | Double the default chunk size
* 6258ae5 | Asha Rao | Asha Rao | Add splitter test
* e636524 | Asha Rao | Asha Rao | Add chunking config
* 81ee9da | Asha Rao | Asha Rao | Add fixed-size splitter
```
<!-- /snippet -->

<!-- snippet: ex3/x22-which-method/04-history-z -->
```text
$ git -C Z log --graph --format='%h | %an | %cn | %s' -6 main
*   6b21010 | Asha Rao | Asha Rao | Merge pull request #12 from feature/overlap
|\  
| * 39301d4 | Lab User | Lab User | Reject an overlap that is not smaller than the size
| * 8743f96 | Lab User | Lab User | Test that overlap repeats characters
| * 5b7fd29 | Lab User | Lab User | Add overlap parameter
* | 1b220ee | Asha Rao | Asha Rao | Double the default chunk size
|/  
* 6258ae5 | Asha Rao | Asha Rao | Add splitter test
```
<!-- /snippet -->

1. Name the method behind X, Y and Z. For each, give the one piece of evidence in the listing that decides it.
2. Two things in these listings would look different after a real merge on GitHub. Which?
3. For each copy, predict the exit status of `git merge-base --is-ancestor 39301d4 main`.
4. Is the tree of `main` the same in the three copies? Give the reason, not a guess.
5. For each copy, write the command that takes the whole pull request back out of `main`. Which one carries a trap for the day you want the feature back?
6. CI ran on the final state of the pull request only. In which copies does `main` contain commits whose own trees were never tested? What does that mean for `git bisect`, and which option helps in one of the copies?

### Exercise 22.3 (Level 2, read and diagnose): The queue that never finishes

Read [`workflows/x22-queue-ci.yml`](workflows/x22-queue-ci.yml). The repository's ruleset on `main` requires the status check `ci`. Until last week, pull requests merged normally. On Monday the team enabled a merge queue on `main`. Since then every pull request that enters the queue waits and is then removed from it, although its own `ci` check is green.

1. On which commits must the required check now be reported? Who created those commits, and under which branch prefix do they live?
2. Why does the workflow in the file never report on them?
3. Write the change. It is one line.
4. After the change, who chooses the merge method for a pull request in the queue?
5. When is a merge queue the wrong tool? Give the cheaper alternative and what it costs.

### Exercise 22.4 (Level 3, design): A merge method for three teams

Recommend one merge method for each team, name what the team gives up, and name one repository or ruleset setting that must match your choice.

- Team A builds a payments service. An external auditor samples deployed commits and asks for the review of exactly that commit ID. A rule on `main` requires signed commits.
- Team B builds an internal evaluation dashboard. Pull requests are small and short-lived. Branches are full of "wip" and "fix typo" commits. They want a one-command revert per change.
- Team C maintains an open-source library. Maintainers curate every commit, want `git bisect` to stop on single commits, want no merge commits on `main`, and have just proposed to require signed commits on `main`.

For team C, one of its wishes cannot be satisfied by any merge button. Which, why, and what is the documented workaround?

### Exercise 22.5 (Level 4, local simulation): The release that does not contain its fix

```bash
bash labs/ex3/setup-x22-5-release-drift.sh
labs/shell x22-5/you/chunker
```

You are in your clone, on `main`. You last fetched when `v0.8.0` was tagged. A bare repository beside it plays GitHub.

Symptoms:

- The Releases page shows a release `v0.9.0`, created by a product manager in the web interface on Friday. Its notes, typed by hand, say: "Rejects an overlap that is not smaller than the chunk size."
- A customer on `v0.9.0` reports that `split(text, size=100, overlap=100)` never returns.
- The build machine checks out `main`, runs `git describe`, and labels its image with a name that starts with `v0.8.0-`.

Establish from the repository: what kind of object `v0.9.0` is, which commit it names, whether that commit contains the fix, why the build machine prints an older version, and which commit a correct release must name. Then do the Git half of the lowest-risk correction, and write down the GitHub half as `gh` commands without running them.

Self-check:

- [ ] You can state, with a command for each, the object type of both tags.
- [ ] You can show with one command that no tag contains the fix before your correction.
- [ ] After your correction, `git describe` of the fix commit prints an exact tag name, and `v0.9.0` still names the commit it named before.
- [ ] You did not move, delete or re-create `v0.9.0`, and you can give the reason.
- [ ] Your `gh` commands cannot create a tag by accident.

### Exercise 22.6 (Level 3, read and diagnose): Auto-merge did what it was told

Repository settings: auto-merge is allowed. The ruleset on `main` requires one approval and the check `ci`; neither "dismiss stale approvals" nor "approval of the most recent push" is selected.

1. The author enables auto-merge. A reviewer approves at 10:00. At 10:05 the author, who has the Write role, pushes one more commit. `ci` turns green at 10:12 and the pull request merges at 10:12. Was any rule broken? Which setting decides whether the last commit lands unreviewed?
2. Same repository, but the push at 10:05 comes from a contributor without write permission, through a fork with maintainer edits. What does the documentation say happens to auto-merge?
3. In another repository there is no ruleset at all. A developer looks for the auto-merge option on a new pull request and cannot find it. Why?
4. What does `gh pr merge 12 --auto --squash --match-head-commit <ID>` add? Which problem of part 1 does it address from the terminal?

### Exercise 22.7 (Level 5, production incident): "The approved commit is not on main"

An auditor samples the commit that was deployed on 9 September, `461e56e` in history Y of Exercise 22.2, and asks for its review. The pull request page for #12 shows an approval, but its head commit is `39301d4`, and `461e56e` appears nowhere in the pull request's commit list. Evidence and opinions:

- An engineer says: "Somebody must have force-pushed `main` after the merge."
- `git merge-base --is-ancestor 39301d4 main` exits with status 1.
- The repository allows only squash merging.
- The head branch `feature/overlap` was deleted after the merge.
- The author field of `461e56e` names the person who pressed the merge button in this local imitation.

1. Is the force-push theory needed to explain the evidence? Which fact explains all of it?
2. The head branch is deleted. From where can the auditor's commit `39301d4` still be fetched on GitHub, and can anybody have rewritten it there?
3. Describe a check, in Git commands, that shows the content that landed is the content of the approved head merged with `main` as it was. What exactly does it prove, and what does it not prove?
4. The auditor's rule is "the reviewed commit ID must be the deployed commit ID". Can this repository satisfy it as configured? What would have to change, and what would the team give up?
5. One statement in the evidence list is true only for the local imitation. Which, and what does the chapter say about the real thing?

---

## Module 23: Governance: rulesets, branch protection, and CODEOWNERS

Chapters: [18, Branch protection and rulesets](../textbook/ch18-branch-protection.md) and [19, CODEOWNERS](../textbook/ch19-codeowners.md).

### Exercise 23.1 (Level 1, read and diagnose): Five predicates

A server sees every push as ref updates of the form (old ID, new ID, ref name). Five ruleset rules are questions about those three values: restrict creations, restrict updates, restrict deletions, block force pushes, require linear history. A branch ruleset on `main` contains restrict deletions, block force pushes and require linear history. A tag ruleset on `v*` contains restrict updates, restrict deletions and block force pushes. Both are active and their bypass lists are empty. For each push, name every rule that rejects it, or write "accepted".

1. `git push origin main`, where the new commit has the old tip as its only parent
2. `git push origin main`, where the new tip is a merge commit made with `git merge --no-ff`
3. `git push --force-with-lease origin main` after `git commit --amend`
4. `git push origin --delete main`
5. `git push origin v2.0.0`, where no tag of that name exists on the server
6. `git push --force origin v1.9.0`, where the tag exists and you moved it locally
7. `git push origin feature/x`, a new branch

Then: in case 3, your Git printed `! [remote rejected]`. What would `! [rejected]` have meant instead, and why did `--force-with-lease` not help?

### Exercise 23.2 (Level 2, local simulation): Which branches does the pattern cover?

GitHub documents that ruleset targets are matched with Ruby's `File.fnmatch` and the `File::FNM_PATHNAME` flag. Fill in the table with "match" or "-" before you run anything.

| Pattern | `main` | `release/2.4` | `release/2.4/hotfix-812` | `releases` | `hotfix-812` | `hotfix/812` | `dependabot/uv/main-1f2e` |
|---|---|---|---|---|---|---|---|
| `release/*` | | | | | | | |
| `release/**/*` | | | | | | | |
| `hotfix*` | | | | | | | |
| `*` | | | | | | | |
| `**/*` | | | | | | | |
| `*/*` | | | | | | | |

Then answer:

1. A team protects "all release branches" with `release/*`. Which branch in the table is unprotected, and what tells them so?
2. Which pattern would you use for "every branch", and which special target would you use for the default branch in the REST API? Why is the special target better than the name `main`?
3. Which `gh` command asks GitHub which rules apply to a branch name, and does the branch have to exist?

To check yourself afterwards: `labs/run ex3/x23-fnmatch`.

### Exercise 23.3 (Level 3, read and diagnose): Review this ruleset

A two-person team (both have the Write role; one of them is also the repository administrator) maintains `northwind-ml/chunker`. Release branches are named `release/2.4`, and hotfix branches for a release `release/2.4/hotfix-812`. The repository settings allow merge commits and rebase merging; squash merging is switched off. `CODEOWNERS` was added to `main` in August; `release/2.4` was cut in June. The workflow that reports the check `build` has a `paths:` filter on `chunker/**`.

With read access you fetch the team's only ruleset. It is active, targets branches matching `release/*`, and these are its rules:

```json
[
  { "type": "non_fast_forward" },
  { "type": "required_linear_history" },
  { "type": "pull_request",
    "parameters": {
      "required_approving_review_count": 2,
      "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": true,
      "require_last_push_approval": false,
      "required_review_thread_resolution": false,
      "allowed_merge_methods": ["squash"] } },
  { "type": "required_status_checks",
    "parameters": {
      "strict_required_status_checks_policy": false,
      "required_status_checks": [ { "context": "build" } ] } }
]
```

The rules are written with the parameter names of Chapter 18, sections 18.7 and 18.18. This is an exercise document, not output from GitHub.

1. Find every way in which this ruleset blocks all merges, protects less than the team believes, or leaves a loophole. There are at least seven. For each: the consequence, the section that documents it, and the change.
2. Your JSON has no `bypass_actors` key. Does that mean the bypass list is empty? Why?
3. The administrator says: "If it gets in the way I can always push, I am the admin." Is that true under a ruleset? Was it true under a classic branch protection rule?

### Exercise 23.4 (Level 3, read and diagnose): Layers

Four things apply to `main` of one repository:

| Layer | Content |
|---|---|
| Organization ruleset, active | block force pushes; pull request with 1 approval |
| Repository ruleset A, active | pull request with 2 approvals and code owner review; required check `ci`, strict |
| Repository ruleset B, disabled | require signed commits |
| Classic branch protection rule on `main` | require linear history; pull request with 1 approval; "Do not allow bypassing the above settings" not selected |

1. List exactly what a pull request into `main` must satisfy.
2. A repository administrator edits ruleset A down to 1 approval and removes the check. What must a pull request satisfy now? What did the administrator fail to loosen, and who could?
3. Which of the four layers can a person with the Read role see, and where?
4. Somebody enables ruleset B on Friday evening. Which merge method stops working at that moment, and which pull requests that would be squash-merged are suddenly blocked?
5. An administrator pushes directly to `main`. Which layers bind them, assuming every bypass list is empty?

### Exercise 23.5 (Level 2, read and diagnose): Eight paths, one CODEOWNERS file

The repository `northwind-ml/ml-platform` has the directories `.github/`, `docs/`, `infra/terraform/`, `libs/eval/` (with subdirectories `metrics/` and `fixtures/`), `services/billing/` and `services/ranker/` (with a subdirectory `config/`). The team `@northwind-ml/billing` has no role of its own on the repository; its members can push through the organization's base permission. All other teams hold the Write role as teams. This is `.github/CODEOWNERS` on `main`:

```text
/.github/                     @northwind-ml/repo-admins
*                             @northwind-ml/platform

/services/ranker/             @northwind-ml/ranking
/services/ranker/             @northwind-ml/sre
/libs/eval/*                  @northwind-ml/ml-eval
!/libs/eval/fixtures/         @northwind-ml/data
/Docs/                        @northwind-ml/docs
/services/billing/            @northwind-ml/billing
/infra/terraform/
*.yaml                        @northwind-ml/platform
```

Reason from the documented rules of Chapter 19. Do not use `git check-ignore`.

1. For each path, name the line that decides and who is requested for review:
   `.github/workflows/deploy.yaml`, `services/ranker/api.py`, `services/ranker/config/prod.yaml`, `libs/eval/metrics/bleu.py`, `libs/eval/fixtures/gold.jsonl`, `docs/runbook.md`, `infra/terraform/main.tf`, `services/billing/invoice.py`.
2. List the faults in the file. There are at least seven. For each, name the rule it violates.
3. Rewrite the file so that it does what its author evidently meant: both the ranking team and SRE can approve ranker changes, the evaluation team owns everything under `libs/eval/` except the fixtures, which the data team owns, and nobody can change the workflows or this file without the repository administrators.
4. Your rewrite is on a branch. Whose approval does the pull request that carries it need, and which file decides?
5. Which API call tests your rewrite for errors before it merges?

### Exercise 23.6 (Level 3, read and diagnose): Four pull requests that will not merge

The ruleset is `labs/ch18/rulesets/main-production.json` from Chapter 18, section 18.18. Each pull request is approved by one person and shows no conflict. For each, name the unmet rule, how you would confirm it, and what unblocks it.

1. A documentation-only pull request. The merge box has said "Waiting for status to be reported" for the check `ci` since yesterday. The CI workflow has a `paths:` filter that lists `src/**` and `tests/**`.
2. A pull request by Ravi. Asha reviewed it, pushed a one-line fix to the branch herself, and then approved it. No one else has reviewed.
3. A pull request by Asha that changes `scripts/deploy.sh`. `CODEOWNERS` on `main` gives `/scripts/` to `@asha-rao` alone. Ravi has approved.
4. A pull request that was green and approved at 09:00. At 09:30 another pull request merged into `main`. Nothing on this pull request has changed since, and `ci` is still green on its head commit.

Then: for case 4, which local command answers "is this branch up to date with `main`", and what are the two consequences of pressing **Update branch** under this ruleset?

### Exercise 23.7 (Level 3, design): Protect a monorepo

Design the protection for `northwind-ml/ml-platform`, a private monorepo on the Team plan. Eighteen engineers in four teams. `main` deploys to staging on every merge; production deploys from tags `v*`. Release branches `release/N.M` receive backports. Dependabot opens pull requests. A release bot, running as a GitHub App, creates the tags. CI takes about twelve minutes; there are about thirty merges a day and the team complains that pull requests go out of date while they wait.

Write: the rulesets you would create (kind, target, rules, sub-options), the bypass list of each with the mode of every entry, the merge method, what CODEOWNERS covers, how the rules roll out, and three things your design deliberately does not do. State the cost of every choice.

The solution has a rubric, not one right answer.

### Exercise 23.8 (Level 5, production incident): "Main is protected. How did a force push get through?"

On Tuesday at 16:42, `main` of `northwind-ml/ranker-service` lost four commits. They have been restored from a teammate's clone. You are asked how it could happen. Evidence:

- The **Rulesets** page shows one active branch ruleset named "protect main". Its history is not available on the organization's plan.
- That ruleset targets `main-*` and `release/*`. Its author says the pattern "covers main and everything like it".
- Under Settings, Branches, there is also a classic branch protection rule for `main`: pull request required, force pushes not allowed. "Do not allow bypassing the above settings" is not selected.
- The organization's audit log has an entry of the type `protected_branch.policy_override` at 16:42 for this repository. The actor is a repository administrator.
- That administrator says: "I ran `git push --force-with-lease`, and the lease is the safe one. It should have refused if anything was wrong."
- A colleague suspects a stolen token, because "an admin would never do that".
- The four lost commits had been pushed to `main` by pull request merges between 16:10 and 16:40.

1. For each of the two protection layers, say whether it applied to `main` at 16:42 and whether it bound this actor. Give the rule from the chapter for each answer.
2. State the root cause in one sentence.
3. What did `--force-with-lease` check, and why did it pass? Use the timeline.
4. What does the evidence say about the stolen-token theory? What would you look at to close it?
5. Write the corrective actions in order: tonight, this week. For each say which gap it closes.
6. After your changes, could an administrator still force-push `main`? What exactly would they have to do, and would you know?

---

## Module 24: Commit signing and verification

Chapters: [14B](../textbook/ch14b-config-tags-signing.md), sections 14B.15 to 14B.18, and [21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.5 to 21B.7.

### Exercise 24.1 (Level 1, read and diagnose): Covered or not covered?

A commit carries a valid SSH signature. For each item, say whether the signature covers it, and what an attacker with push access but without the private key can therefore still do.

1. The content of every file in the commit's tree
2. The commit message
3. The author name and email
4. The committer date
5. The parent commit, and every ancestor behind it
6. The name of the branch the commit is on
7. The repository or fork that serves the commit
8. The fact that the change was reviewed
9. For a signed annotated tag: the tag name written inside the tag object
10. For a signed annotated tag: the ref name under which a server offers that tag object

### Exercise 24.2 (Level 2, local simulation): Five commits, five claims

A repository uses SSH signing. The allowed-signers file lists you and Asha. Ravi has a key that is not in the file. Five commits are made on the branch `feature/retry`, as the transcript shows; `-S` signs with the key in `user.signingKey`, which is yours unless the command says otherwise.

<!-- snippet: ex3/x24-signature-predict/01-setup -->
```text
# allowed_signers lists two principals:
$ cut -d' ' -f1 ~/allowed_signers
you@example.com
asha@example.com
# Five commits on feature/retry, oldest first:
$ printf 'retries: 3\n' > retry.yaml && git add retry.yaml && git commit -q -S -m 'c1 add retry config'
$ printf 'retries: 4\n' > retry.yaml && git commit -q -am 'c2 raise retries'
$ printf 'retries: 5\n' > retry.yaml && git -c user.signingKey=~/keys/ravi.pub commit -q -S -am 'c3 raise retries again (Ravi, his key)'
$ printf 'retries: 6\n' > retry.yaml && git commit -q -S --author='Asha Rao <asha@example.com>' -am 'c4 written by you, author field says Asha'
$ printf 'retries: 2\n' > retry.yaml && git -c user.signingKey=~/keys/asha.pub commit -q -S -am 'c5 lower retries (Asha, her key)'
```
<!-- /snippet -->

(c3 is committed with Ravi's identity and c5 with Asha's; the script switches identity between the lines.)

Predict:

1. For c1 to c5, the letter that `git log --format='%G?'` prints, and the signer (`%GS`) where there is one.
2. The exit status of `git verify-commit` for c2, c3 and c4. One of the three surprises people. Which, and why is it not a bug?
3. On a new branch from `main`: does `git merge --verify-signatures --no-ff feature/retry` succeed? If it does, which signature states are on that branch afterwards?
4. `main` gains one commit and you run `git rebase main` on `feature/retry`, without `-S` and with `commit.gpgSign` unset. What does `%G?` print for the five rebased commits?
5. You run the rebase again with `-S`. What do `%G?` and `%GS` print now, in particular for the commits whose author is Asha or Ravi?
6. In one sentence each: what did the signature on c4 prove, and which check would have caught c4?

To replay afterwards: `labs/run ex3/x24-signature-predict`. The keys are generated fresh on every run, so your commit IDs differ from run to run; the letters do not.

### Exercise 24.3 (Level 2, read and diagnose): What would GitHub display?

The five commits of Exercise 24.2 are pushed to GitHub. Your public key is registered on your account as a signing key. Asha's is registered on hers, and Asha has enabled vigilant mode. Ravi has registered no key and has not enabled vigilant mode. You have not enabled vigilant mode.

Using the table in Chapter 21B, section 21B.6, predict what GitHub displays beside each of c1 to c5: Verified, Partially verified, Unverified, or no badge. Then:

1. Which commit changes its display if you enable vigilant mode too, and to what?
2. Asha never touched c4. What does its display tell a reviewer who knows the table, and what would it have shown if Asha had not enabled vigilant mode?
3. The same key file serves you for authentication. Is it enough that it is on your account as an authentication key? Give the command that registers it for signing.
4. This is a prediction from documentation. Which lab lets you observe it?

### Exercise 24.4 (Level 3, read and diagnose): Four questions from a team that has just required signatures

A team enabled "Require signed commits" on `main` on Monday. By Wednesday it has four questions. Answer each from the documented behavior and cite the section.

1. "GitHub signs the squash commit. Why is this squash merge blocked?"
2. "Why has **Rebase and merge** stopped working, and is there a way to keep a rebased, linear history?"
3. "Maya rotated her signing key last month and deleted the old one from her account. Do her commits from last year now show as Unverified?"
4. "A contractor's laptop was stolen in July. We revoked his key in August. Are the commits a thief might have signed in between marked Unverified now, so that we can find them by the badge?"

### Exercise 24.5 (Level 3, design): A signing policy for a team of eight

Write a one-page signing policy for a team of eight engineers and two bots (Dependabot and a release bot) working on a service that deploys from `main`. Cover: which signature format and why; where private keys live and how many per person; how the team states whom it trusts for local verification; vigilant mode; whether `main` gets the "Require signed commits" rule and what that costs in merge methods; what bots do; key rotation and a lost laptop; and what the policy explicitly does not claim to prove.

The solution has a rubric.

### Exercise 24.6 (Level 5, production incident): Verified, and she was on a plane

On Saturday a commit on `main` of `northwind-ml/billing-export` changed the export destination to an unknown host. The commit page shows the platform lead's avatar, her name, and a **Verified** badge. Evidence:

- The platform lead was on a flight at the commit's timestamp. Her laptop was in her bag, switched off; her signing key has a passphrase and exists only on that laptop.
- A local check of the commit's signature shows that it was made with GitHub's own web-flow key, not with her key.
- The repository has no ruleset on `main`.
- Her account has two-factor authentication. Two weeks ago she authorized a third-party "PR dashboard" OAuth app with the `repo` scope.
- A teammate says: "It is Verified. So it is hers. Maybe she scheduled it."
- Another says: "Timestamps can be forged, so the flight proves nothing."

1. What does this particular Verified badge prove? Quote the chapter's sentence about commits that GitHub signs.
2. Rank three hypotheses by how well they fit the evidence: her signing key was stolen; her session or a token was used to create the commit through GitHub's web interface or API; a colleague with push access forged her author field in a local commit.
3. The second teammate is right about timestamps in general. Which record does not depend on the commit's own dates, and what does it tell you?
4. What happens in the first hour? Order the actions and say which one stops further damage.
5. Which two controls would have limited this, and what would signing alone have changed?

---

## Module 25: GitHub CLI and API

Chapter: [15, GitHub](../textbook/ch15-github.md), sections 15.16 to 15.18.

### Exercise 25.1 (Level 1, do it on GitHub): Ask the CLI, not the browser

In your clone of `YOUR-ORG/practice-repo`, in your normal shell:

```bash
gh auth status
gh repo set-default --view
gh pr list --state all --json number,title,state --jq '.[] | "#\(.number) \(.state) \(.title)"'
gh api repos/{owner}/{repo} --jq '{full_name, default_branch, visibility, fork}'
gh api rate_limit --jq '.resources.core'
gh ruleset list
gh ruleset check --default
```

Self-check:

- [ ] For each command you can say whether it could have changed anything on GitHub, and for the two `gh api` calls which HTTP method was used.
- [ ] You can say where `gh` found `{owner}` and `{repo}`, and how you would point one command at another repository.
- [ ] You know which account `gh` acts as, and where its token is stored, from the first command's output.
- [ ] You can say how many requests per hour your token has, and how many an unauthenticated script on a shared runner has.
- [ ] You can explain why `gh ruleset` has no `create` subcommand and what you use instead.

### Exercise 25.2 (Level 2, read and diagnose): Which of these changes something?

For each command, name the HTTP method, say whether it changes anything on GitHub, and give its risk label. Two of them do not do what their author meant. Do not run 2, 4 or 7.

```bash
gh api repos/{owner}/{repo}/pulls                                                      # 1
gh api repos/{owner}/{repo}/pulls -f state=closed                                      # 2
gh api -X GET repos/{owner}/{repo}/pulls -f state=closed --paginate --jq '.[].number'  # 3
gh api --method PUT repos/YOUR-ORG/practice-repo/rulesets/123456 -f enforcement=disabled   # 4
gh api graphql -F owner='{owner}' -F name='{repo}' -f query='
  query($name: String!, $owner: String!) {
    repository(owner: $owner, name: $name) { releases(last: 3) { nodes { tagName } } }
  }'                                                                                   # 5
gh api -H 'X-GitHub-Api-Version: 2026-03-10' repos/{owner}/{repo}                      # 6
gh api --method DELETE repos/YOUR-ORG/practice-repo/rulesets/123456                    # 7
gh api repos/{owner}/{repo}/pulls --jq 'length'                                        # 8
```

1. Which command was meant as a read and is sent as a write? Quote the rule from `gh api --help`.
2. Command 8 prints 30 in a repository with 140 open pull requests. Why, and what is the correct command?
3. Command 5 is sent with which HTTP method, and does it change anything?
4. What does the header in command 6 do, and what does a request get without it?

### Exercise 25.3 (Level 2, local simulation): Six filters, offline

`gh api --jq` takes the filter language of `jq`, so filters can be rehearsed with `jq` on a file. `labs/ex3/files/pulls-pages.json` is a practice document written for this course, shaped like the result of `gh api --paginate --slurp` on a pull request list: an array of pages, each page an array of pull requests. It is not output from GitHub. Its shape:

<!-- snippet: ex3/x25-jq/01-shape -->
```text
$ jq 'length' pulls-pages.json
2
$ jq 'map(length)' pulls-pages.json
[
  3,
  2
]
$ jq -c '.[0][0]' pulls-pages.json
{"number":31,"title":"Add overlap to the splitter","state":"open","draft":false,"created_at":"2026-09-07T05:10:00Z","user":{"login":"lab-user"},"base":{"ref":"main"},"head":{"ref":"feature/overlap"}}
```
<!-- /snippet -->

Copy the two JSON files from `labs/ex3/files/` to a scratch directory and write one `jq` command for each task:

- a. The total number of pull requests across all pages.
- b. One line `#NUMBER TITLE` for every pull request that is not a draft and targets `main`.
- c. A compact JSON array with one object per base branch: its name and the number of pull requests against it.
- d. The number and creation time of the oldest pull request.
- e. The distinct logins of human authors, one per line, where a bot is any login that ends in `[bot]`.
- f. From `rulesets-list.json` (a plain array): ID, name and enforcement of every ruleset that is not active.

Then: what does `jq -r '.[] | .number' pulls-pages.json` do, and what does that tell you about `--slurp`?

### Exercise 25.4 (Level 3, read and diagnose): Five scripts that stopped working

Name the cause of each and the smallest correct change.

1. A report of "all open pull requests" has shown exactly 30 for three weeks.
2. A nightly job lists pull requests of sixty public repositories with unauthenticated `curl`. It worked from a laptop. On the shared CI runner it fails with status 403 from the first request on.
3. `gh pr list` works in one terminal tab and fails with an authentication error in another, on the same machine, in the same clone.
4. `gh api repos/northwind-ml/billing-export` answers `404 Not Found`. The engineer has the repository open in a browser.
5. A script that sends `X-GitHub-Api-Version` with a date from several years ago starts receiving `410 Gone`.

Then: case 2 and case 4 both look like permission problems and neither is about the repository's roles. What do you check first in each?

### Exercise 25.5 (Level 3, design): Merge when green, safely

Write a shell fragment of at most fifteen lines that, for a pull request number in `$PR`: waits until the required checks have finished, stops with a clear message if any failed, and squash-merges only if the head commit is still the one you reviewed, whose ID is in `$REVIEWED`. Use `gh` only, test exit statuses, and do not parse human-readable output.

State which exit status of `gh pr checks` means "still pending", why you pass `--required`, what `--match-head-commit` protects against, and why the fragment must not use `--admin`.

The solution has a rubric and one model fragment. It was checked against `--help`; it was not run against GitHub.

### Exercise 25.6 (Level 3, design): An identity for a bot

A "stale pull request reporter" must, once a day, read the open pull requests of forty repositories in one organization and post a comment on those without activity for two weeks. Three proposals are on the table:

- A. A classic personal access token of the team lead with the `repo` scope, stored as an organization secret; a cron job polls every repository every five minutes "to be responsive".
- B. A fine-grained personal access token of a machine user, selected repositories, read on pull requests.
- C. A GitHub App installed on the forty repositories, with the permissions it needs, reacting to webhooks and running one daily sweep.

For each: what it authenticates as, what a leak reaches and for how long, what happens when a person leaves, and whether it can do the job at all. Then recommend one, and say what the rate limits mean for proposal A.

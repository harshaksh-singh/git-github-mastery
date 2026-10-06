# V116: Forks and the fork network

- **Part.** 5: GitHub
- **Module.** 19
- **Planned minutes.** 20
- **Prerequisites.** V043, V115
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), sections 15.6 and 15.7
- **Demo scripts.** `labs/ch15/fork-network.sh`; GitHub-side walkthrough of the fork step of Lab 21.1

## HOOK

**[ON SCREEN]** "Fork deleted within the hour. Is the key gone?"

An intern pushes a staging key to a branch of her fork of your public repository. A fork is a second repository on GitHub, hers, connected to yours. Someone notices. The fork is deleted within the hour. The CTO asks the question everyone hopes has a short answer: is the key gone?

No. And the answer is worse than "it might be cached somewhere". The commit is reachable through your own repository's URL, by anyone who knows its ID. GitHub documents this behaviour. This video shows you a local model of it, so that you understand the mechanism well enough to act correctly in the first five minutes. Hold on to those five minutes. They come back at the end.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video you learned to sort everything into Git data and GitHub objects. A fork is the first place where that sorting has a security consequence.

We cover two short sections of Chapter 15. Section 15.7, forks and the fork network, is the body of the video. Section 15.6, stars and watchers, is a short addendum at the end of the concept, because forks, stars and watchers are the three counters at the top of every repository page and all three are misread.

One replay, `labs/ch15/fork-network.sh`. Be clear about what it is. GitHub documents the behaviour of fork networks and not the mechanism. Git has a documented mechanism of its own with the same property, namespaces, and the demo uses it as a model. It is not a claim about how GitHub is built.

The model ends with `git gc --prune=now`, 🔴 DANGEROUS, on a throwaway repository. You know its five answers from Part 4. One GitHub CLI command is discussed and not run: `gh repo sync --force`, also 🔴.

## LEARNING OBJECTIVES

After this video you can:

- Describe a fork as a separate repository that shares object storage with its network.
- Show locally that a commit pushed to a fork can be reached by ID through the upstream.
- Say what deleting a fork or a branch does and does not remove.
- Explain what stars and watchers are and are not evidence of.

## CONCEPT

In one sentence: a fork is a second repository on GitHub with its own refs, settings and permissions, connected to the repository it was made from, and storing its Git data together with it.

Why do forks exist? So that people without write access to a repository can publish commits somewhere and propose them. The fork is theirs: their permissions, their branches.

What GitHub documents, from its forks reference.

**[ON SCREEN]** Five documented facts.

One. A fork has its own branches, tags, issues, pull requests, Actions, labels and wiki, and its own permissions. Forks of public repositories are public and forks of private repositories are private. A fork's visibility can't be changed by itself.

**[ANIMATION]** cards: id=facts question=Five_documented_facts cards=A_fork_is_its_own_repository:its_own_branches,_issues_and_permissions|The_network_shares_Git_data:even_after_a_fork_is_deleted|Deleting_a_repository:private_forks_go,_a_public_fork_becomes_the_upstream|Branch_and_tag_rulesets_are_not_inherited:push_rulesets_apply_to_the_whole_network|Restore_within_90_days:unless_the_fork_network_is_not_empty numbered=on pace=quick

**[ANIMATION]** step: 2

Two. A repository network is the upstream repository, its forks, and forks of those forks. The upstream is the repository the forks were made from. And then the sentence that matters: "Repositories in the network share Git data." Commits pushed to any repository in a network "can be accessible from other repositories in that network, including the upstream repository", and this holds "even after a fork is deleted". Owners of an upstream repository can read all forks in the network.

**[ANIMATION]** step: 3

Three. Deleting a private repository deletes its private forks. Deleting a public repository makes an active public fork the new upstream. Removing a person's access to a private repository deletes their forks of it.

**[ANIMATION]** step: 4

Four. Branch and tag rulesets aren't inherited by forks. Push rulesets apply to the whole network. A ruleset is a named list of rules for chosen refs.

**[ANIMATION]** step: 5

Five. A deleted repository can be restored within 90 days, unless its fork network is not empty.

**[ANIMATION]** end

Inside `.git`, on your side: to your clone a fork is one more remote. The parent-and-fork relationship is a GitHub object that no ref or configuration key records. The `upstream` remote that `gh repo fork` and `gh repo clone` add is a convenience in `.git/config`, not the relationship.

**[ANIMATION]** stores: id=net boxes=acme-ml/prompt-registry:refs_of_the_upstream|*object_database:one_for_the_whole_network|you/prompt-registry:refs_of_the_fork rows=1:B:..._bf7889c|1:A:refs/heads/main|2:C:refs/heads/main|3:B:915a81e_(the_key)@bad|3:C:debug/staging-config arrows=1:A1>B1:|2:C1>B1:|3:C2>B2:|4:A>B2:by_ID mono=on title=One_object_database,_two_sets_of_refs at_1=30 at_2=62

**[ANIMATION]** step: 2

Now connect this to Part 4. You know that an object exists independently of the refs, the names that reach it, and that deleting a ref deletes a name. A fork network is that fact at the scale of a platform: several sets of refs over one store of objects. Deleting a fork deletes one set of refs.

**[ANIMATION]** end

How long does an unreachable commit, one that no ref reaches, remain on GitHub? The textbook is explicit about what is not known: the course's research found no documented retention period for unreachable commits. So you must not plan on it disappearing.

Keeping a fork current has one dangerous command. According to `gh repo sync --help`, a sync is a fast-forward "except when the `--force` flag is specified, then the two branches will be synced using a hard reset". The five answers for `gh repo sync --force`. It changes the destination branch of the fork. It can destroy commits on that branch that the source doesn't have. Preview with `git log upstream/main..origin/main` after a fetch. Recovery needs a clone that still has those commits. It's appropriate only when the fork's branch is meant to be an exact copy of its parent.

Now the addendum, section 15.6. A star is a bookmark and a public signal. It feeds rankings, in GitHub's words "many of GitHub's repository rankings depend on the number of stars", and anyone can list the stargazers of a repository they can read. Watching is a notification subscription. You can narrow it to chosen event types such as releases and security alerts. By default you automatically watch repositories you create and repositories you are given push access to, except forks. An account can watch at most 10,000 repositories.

Neither is evidence of quality. Stars can be manufactured: the course's research cites a network of more than 3,000 accounts that distributed malware through repositories made to look popular. And a star count says nothing about who controls a repository today. A useful subscription is narrow: releases and security alerts of the dependencies you ship.

## MENTAL MODEL

**[ANIMATION]** step: net.2

The textbook's analogy: a branch office that keeps its own ledger and uses head office's warehouse. Each office has its own list of goods, its refs. The goods, the objects, are in one building, and anyone who knows a crate's serial number can ask either office for it.

The analogy breaks when an office closes: its list is gone and the crates remain.

The serial number is the commit ID. Whoever has it doesn't need the list.

## DIAGRAM

**[ANIMATION]** step: net.3

**[DIAGRAM]** One box for the platform. Objects on top, two sets of refs below.

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

In the middle is the object database: among others, commit `bf7889c`, the tip of `main`, and commit `915a81e`, the commit with the key.

On the left, the refs of the upstream repository: one branch, `main`. On the right, the refs of the fork: `main`, and the debug branch that points at `915a81e`.

Try it now, thirty seconds, on paper. Copy the picture: one box of objects, two lists of refs. Then cross out the fork's list, and look at what's left. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: net.4

The upstream has no ref that reaches `915a81e`. But both names are doors into the same room.

**[ANIMATION]** stores: id=gone boxes=acme-ml/prompt-registry:refs_of_the_upstream|*object_database:one_for_the_whole_network|you/prompt-registry:deleted rows=1:B:..._bf7889c|1:A:refs/heads/main|1:C:refs/heads/main@ghost|1:B:915a81e_(the_key)@bad|1:C:debug/staging-config@ghost arrows=1:A1>B1:|2:A>B2:by_ID mono=on title=The_fork_is_deleted,_the_object_is_not pace=quick

Crossing out the right-hand set of refs is deleting the fork. The object database doesn't change.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch15/fork-network
```

The platform is one bare repository, a repository with no working tree. The upstream, `acme-ml/prompt-registry`, is a namespace in it.

```bash
git init -q --bare platform/network.git
GIT_NAMESPACE=acme-ml git -C seed push -q ../platform/network.git main
git -C platform/network.git for-each-ref --format="%(refname)"
find platform/network.git/objects -type f | wc -l | tr -d ' '
```

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

One ref, under `refs/namespaces/acme-ml/`, and 27 object files.

Now forking.

```bash
git -C platform/network.git update-ref refs/namespaces/you/refs/heads/main refs/namespaces/acme-ml/refs/heads/main
find platform/network.git/objects -type f | wc -l | tr -d ' '
```

The fork now exists. How many object files are there? Say it out loud. I'll wait.

**[PAUSE]**

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

Twenty-seven before, twenty-seven after. Forking wrote one ref. No object was copied.

```bash
GIT_NAMESPACE=you git clone -q platform/network.git you/prompt-registry
cd you/prompt-registry
git branch -a
```

<!-- snippet: ch15/fork-network/03-clone-fork -->
```text
$ GIT_NAMESPACE=you git clone -q platform/network.git you/prompt-registry
$ cd you/prompt-registry
$ git branch -a
* main
  remotes/origin/main
```
<!-- /snippet -->

Now the mistake. The key in this file is a fake made for the lab.

```bash
git switch -q -c debug/staging-config
printf 'STAGING_API_KEY=FAKE-KEY-for-the-lab\n' > staging.env
git add -f staging.env && git commit -q -m "Add staging config for debugging"
GIT_NAMESPACE=you git push -q origin debug/staging-config
git rev-parse HEAD
```

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

Note `git add -f`: the file was ignored, and the flag forced it in. Three new objects went into the one object database: 30 now. The commit ID begins `915a81e`.

```bash
GIT_NAMESPACE=acme-ml git ls-remote platform/network.git
GIT_NAMESPACE=you git ls-remote platform/network.git
```

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

Each repository lists only its own refs. The upstream doesn't list the debug branch.

Now a visitor who knows nothing but the upstream repository and the commit ID.

```bash
GIT_NAMESPACE=acme-ml git clone -q platform/network.git visitor/prompt-registry
cd visitor/prompt-registry
GIT_NAMESPACE=acme-ml git fetch origin 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
git show --stat --format="%h %s" FETCH_HEAD
```

Quick quiz, two options. The upstream has one branch, and it doesn't contain this commit. Does the fetch by ID succeed, yes or no? Say it out loud.

**[PAUSE]**

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

**[ANIMATION]** step: net.4

It succeeds. If you said no, you were thinking in branches, and that's a sound instinct. But the upstream served a commit that none of its refs reaches, because the object is in the store it shares with the fork.

Delete the fork.

```bash
git -C platform/network.git for-each-ref --format='delete %(refname)' refs/namespaces/you | git -C platform/network.git update-ref --stdin
git -C platform/network.git for-each-ref --format="%(refname)"
git -C platform/network.git cat-file -t 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
```

The fork's refs are gone. What does `cat-file -t` say about the commit? Make your prediction.

**[PAUSE]**

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

**[ANIMATION]** step: gone.2

`commit`. Deleting the fork removed refs and nothing else. So is the key gone? No.

```bash
git -C platform/network.git gc --quiet --prune=now
git -C platform/network.git cat-file -t 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
```

<!-- snippet: ch15/fork-network/08-prune -->
```text
# Only when the server prunes unreachable objects does the commit cease to exist there:
$ git -C platform/network.git gc --quiet --prune=now
$ git -C platform/network.git cat-file -t 915a81e1e3ff7856fb06c7b1863ec0c4baf6d2b5
fatal: git cat-file: could not get object info
[exit status: 128]
```
<!-- /snippet -->

In the model, the commit dies when the server prunes unreachable objects. You don't control that step on GitHub, and no retention period is documented. One more caveat from Git's own manual: namespaces "are not effective for read access control". The model has the same hole as the thing it models.

**[ON SCREEN]** GitHub walkthrough: only the step that creates the fork, from Lab 21.1. The interface changes; the lab text and the documentation are the reference. No output is shown.

On the page of the repository you want to fork, use the control that creates a fork, choose your account as the owner, and confirm. On the new repository's page, look directly under its name: the page shows the fork relation, "forked from" and the parent's name. That line is the GitHub object. Clone the fork and look for it in `.git/config`: you will find remotes, and no record of the relation. Lab 21.1 itself, the full cycle, runs locally in the lab shell with three repositories and is the subject of a later video.

## COMMON MISTAKES

Five mistakes to watch for.

1. Deleting a fork or a branch to remove a leaked secret. Root cause: deletion removes refs; the objects stay in the store the network shares and remain fetchable by ID.
2. Assuming the upstream is unaffected by what happens in forks. Root cause: commits pushed to any repository in a network can be accessible from the others, including the upstream.
3. Looking for the fork relationship in `.git/config`. Root cause: it is a GitHub object; the `upstream` remote is a convenience.
4. Running `gh repo sync --force` on a fork branch that has its own commits. Root cause: with `--force` the sync is a hard reset to the parent's branch.
5. Choosing a dependency by its star count. Root cause: a star is a bookmark that can be manufactured and says nothing about who controls the repository today.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: gone.2

Now, out of the lab. Back to the intern's key, and the first five minutes. The key was published the moment the push to the public fork finished. Deleting the fork changed which names list the commit, not whether the object can be fetched.

**[ANIMATION]** end

So the order of actions is fixed. Revoke the key first. That's the only action that makes the leaked value worthless, and it doesn't depend on anything GitHub does. Then decide whether removal of the commit is worth requesting. The prevention is a secret store and push protection, which Chapter 21B covers together with the full response procedure.

Notice what didn't help in this story: the fact that `staging.env` was in `.gitignore`. The file was added with `-f`.

## PRACTICE EXERCISE

Your turn. Do Exercise 19.4, "What a clone receives, and where a keyword travels", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Before each command, predict which refs and which objects each repository holds, and where a piece of text in a commit message ends up.

The challenge is Exercise 19.5, "The fork that was deleted", in the same file.

## INTERVIEW QUESTION

Question 241 of the CTO question bank:

> "A commit with a credential was pushed to a fork of your public repository, and the fork was deleted. What is still true, what does GitHub document, and what do you do first?"

**[PAUSE]**

**[ANIMATION]** step: gone.2

Answer out loud. A strong answer has the three parts the question asks for, in that order. It separates what is documented from what is unknown, and says so. Its first action doesn't depend on the platform. It closes with prevention, and it doesn't claim that anything was "removed from history".

## RECAP

Let's land this.

You should now be able to say:

- A fork is its own repository with its own refs and permissions; the network shares Git data.
- A commit pushed anywhere in a network can be fetched by ID through other repositories of the network, even after the fork is deleted.
- Deleting a fork or a branch removes names, not objects; no retention period for unreachable commits is documented.
- A leaked credential is revoked first.
- Stars are bookmarks and watching is a subscription; neither is evidence of quality.

## HOMEWORK

Read sections 15.6 and 15.7 of [Chapter 15](../../textbook/ch15-github.md).

**[ANIMATION]** step: gone.2

Today you watched a deleted fork leave its commit behind, and you know the first move: revoke. If that still feels unsettling, good. It should. Next time: issues, projects, discussions, packages, templates and health files. Until then, look at the state first and type second. See you in the next one.

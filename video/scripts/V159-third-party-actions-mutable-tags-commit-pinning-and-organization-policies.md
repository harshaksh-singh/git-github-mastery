# V159: Third-party actions, mutable tags, commit pinning, and organization policies

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 22
- **Prerequisites.** V081, V158
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.7 and 21A.8
- **Demo scripts.** `labs/ch21a/mutable-tag.sh`; then the files [`workflows/12-secure.yml`](../../workflows/12-secure.yml) and [`workflows/ACTION_PINS.md`](../../workflows/ACTION_PINS.md)

## HOOK

**[ON SCREEN]** One line of a workflow, unchanged for two years: `uses: some-owner/some-action@v4`.

Your repository hasn't received a commit in a week. Your workflow file hasn't changed in two years. This morning your job runs code that didn't exist yesterday, with your job's token and every secret the job holds.

Nobody touched your repository. Somebody moved a tag in another one. That somebody was either a maintainer of the action or a person holding a maintainer's token, and from your side of the line you can't tell which.

You'll reproduce the move locally in three commands, with a bare repository playing the action's repository. A bare repository is one with no working tree, like a server's. Then you'll see the one form of that line that wouldn't have changed. Keep that promise in mind. You'll collect on it in the demo.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is part five of the model: third-party actions. An action is a packaged, reusable step that a workflow calls with a `uses` line. It downloads and runs someone else's code inside your job.

Of the five parts, this is the one that rests most directly on Git. The chapter said at the start that Git contributes exactly two facts to the security model. A tag is a ref, a name that holds a commit's ID, and it can be moved. A commit ID names content that can't change. Both are things you've known since Part 1 and Part 4 of this course. Here they decide what code runs next to your secrets.

Three topics. What a `uses` line trusts. How to write a pin, how to keep it current, and what a pin doesn't protect against. And organization policies: the settings that move some of these rules from "every author must remember" to "the platform refuses".

The demonstration is Git, not GitHub Actions, which is why it can be shown locally.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- explain what `uses: owner/action@v4` trusts;
- show locally that a tag can be moved to another commit without any change in the workflow that names it;
- pin an action to a full commit ID and keep the pin current;
- name three things pinning does not protect against;
- say what organization policies for allowed actions can enforce.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**In one sentence.** `uses` with an owner, a repository and a ref downloads and runs someone else's code inside your job, and only a full commit ID guarantees that it is the code you reviewed.

**Precisely.** From GitHub's secure use reference. A compromised action "would have access to all secrets configured on your repository, and may be able to use the `GITHUB_TOKEN` to write to the repository". And: "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release." A commit SHA is the commit ID, and immutable means it can never change. Tags are a matter of trust: "Pin actions to a tag only if you trust the creator… a tag can be moved or deleted if a bad actor gains access to the repository." The same applies to reusable workflows.

Quick quiz. Your workflow says `@v4`, and the file never changes. When is that tag looked up? A, once, on the day you wrote the line. B, again on every run. Your answer?

**[PAUSE]**

B, on every run. So what does `@v4` trust? Three things at once. That the author is honest. That nobody else can push to the author's repository. And that both stay true on every future day your workflow runs, because the reference is resolved again on every run.

**[ON SCREEN]** The two forms, from section 21A.7.

```yaml
# Unsafe: resolved again on every run, to whatever the tag points at then.
- uses: actions/setup-python@v7

# Safe: the commit, with the version as a comment for humans and for Dependabot.
- uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
```

**Writing a pin.** Take the commit ID from the action's own repository. The reference adds a check: verify that it's from the action's repository and not from a fork of it. The course's pin file shows the command, `git ls-remote --tags`, which needs no login.

**Maintaining a pin.** Pins don't update themselves, and that's the point. So you let Dependabot, GitHub's dependency update feature, propose the updates.

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

That's the documented configuration. And one behavior to know: since the fourteenth of July 2026, version updates wait a default cooldown of three days after a release before a pull request is opened. Security updates are immediate, and the `cooldown` option configures it. The textbook's reading: a cooldown gives the ecosystem time to notice a malicious release before you adopt it.

**The limits of pinning.** The textbook says: state these whenever you recommend it.

First. A pin protects against a moved tag, but, quoting the Phase 0 report, "not against a malicious commit pinned deliberately or against unpinned actions nested inside composite actions". A composite action is an action that bundles several steps. So: read the diff of a pin update.

Second. Quoting GitHub: "Dependabot only creates alerts for vulnerable actions that use semantic versioning and will not create alerts for actions pinned to SHA values." Pinning trades automatic alerts for immutability. Version updates, and advisories you read yourself, fill the gap.

Third. A remote script fetched and executed in a `run` step, the pattern of downloading with `curl` and piping into a shell, is the same risk class with no pin available. That's the Codecov case of video 162.

Fourth, a nuance. Immutable releases, generally available since the twenty-eighth of October 2025, make a published release's tag unchangeable once a maintainer enables the feature. `astral-sh/setup-uv` has used them since version 8.0.0. But you can't see from a `uses` line whether a tag is protected this way. So the pin remains the rule.

**[ON SCREEN]** Callout: Unverified. "Immutable actions", meaning actions published as packages, had no general-availability announcement that the research could find by 1 October 2026, and the secure-use page still calls commit pinning "currently the only way". GitHub's 2026 roadmap describes workflow-level dependency locking as future work; it has not shipped.

**Organization policies. In one sentence:** policies move three of this chapter's rules from "every author must remember" to "the platform refuses".

**[ON SCREEN]** The table of section 21A.8. The labels are quoted from the documentation; the interface changes, so trust the linked page over the table.

Allowed actions and reusable workflows. The choices: allow all. Only those in the owner's organization or enterprise. Or the owner plus a selection, with switches for actions created by GitHub and by verified Marketplace creators, and a pattern list. Available on all plans since the fifth of February 2026.

Blocking. An entry prefixed with an exclamation mark blocks a specific action or version. Since the fifteenth of August 2025.

"Require actions to be pinned to a full-length commit SHA". With it, any workflow that attempts to use an action that isn't pinned will fail, including GitHub's own actions. One exception is stated: reusable workflows can still be referenced by tag.

The workflow permissions default: the read-only token of video 156. A restrictive organization default disables the permissive option below it.

Fork pull request approval: who needs approval before a `pull_request` run starts.

Workflow execution protections: actor rules, for who may trigger workflows, and event rules, for which events may run. They're built on rulesets, GitHub's named lists of rules, at enterprise, organization and repository level.

And "Allow GitHub Actions to create and approve pull requests": off by default for new personal repositories. Keep it off, so that a workflow can't approve its own change.

**The change dated 2 November 2026.** With execution protections, GitHub introduced a default event rule. For public repositories that don't already have an applicable event policy, a default rule disables `pull_request_target`. It initially runs in evaluate mode, and GitHub announced that on the second of November 2026 it is enforced automatically for affected repositories. That date lies after the course baseline, so check the changelog on the day you watch this. Private and internal repositories aren't affected. A maintainer can explicitly allow the event, optionally for named workflow files. The textbook's advice for a public repository with a labeler or a welcome bot on that trigger: decide before that date. Migrate it, or allow it deliberately after reviewing it against section 21A.5.

**Policies do not replace review of the files.** The control for that is a code-owner rule on `.github/workflows/`, enforced by a ruleset, as you set it up in video 136.

## MENTAL MODEL

**[ANIMATION]** graph: 80827f4-5de1e2d main; 80827f4 tag:v1; HEAD=main => 80827f4-5de1e2d main tag:v1; HEAD=main title=An_address_can_move,_a_fingerprint_cannot

**[ANIMATION]** step: state-1

**Analogy,** from the textbook. A tag is a street address, and a commit ID is a fingerprint. Whoever owns the plot can put up a different building at the same address overnight.

The textbook says the analogy breaks in your favor. A fingerprint can in principle be shared by two people. Forging a commit ID means, in GitHub's words, producing "a SHA-1 collision for a valid Git object payload".

**[ANIMATION]** step: state-2

Keep both halves. An address tells you where to go, and somebody else decides what stands there. A fingerprint tells you what you'll find, and nobody can change that.

**[ANIMATION]** end

Then add the limit, so that you don't oversell it. The fingerprint identifies the building. It says nothing about whether the building is sound. A pinned commit can be malicious if it was pinned deliberately, and it can itself call other actions by tag. Pinning answers one question: is this the code I reviewed? It doesn't answer: was the code I reviewed good?

## DIAGRAM

Try it now, thirty seconds, on paper. Write one workflow line that ends in `@v1`. Draw a tag and two commits. Point the tag at the first commit, then move its arrow to the second. What did you change in the workflow line? Say it out loud.

**[PAUSE]**

**[DIAGRAM]** One workflow line on the left. A tag in the middle. Two commits on the right. Draw the first arrow from the tag to the first commit. Then, without touching the workflow line, move the tag's arrow to the second commit. Last, add the pinned form below with its arrow straight to the first commit.

```text
   your workflow (unchanged)              the action's repository

   uses: owner/report-size@v1  ------->  refs/tags/v1 ----+
                                                          |   yesterday
                                                          +----------------> commit 80827f4
                                                          |                  (the code you reviewed)
                                                          |   today, after
                                                          |   git push --force origin v1
                                                          +----------------> commit 5de1e2d
                                                                             (code you never saw)

   uses: owner/report-size@80827f43993c0dc6fc8324685d01e720707e5429  ------> commit 80827f4
                                                                             yesterday, today,
                                                                             and on every later run
```

**[DIAGRAM]** The top line did not change, and what it runs did. The bottom line cannot change what it runs without a commit to your own repository.

Nothing. The top line didn't change, and what it runs did. The pinned line at the bottom can't change what it runs without a commit to your own repository.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21a/mutable-tag`. Git, in the sandbox. A bare repository stands for an action's repository, and `v1` is an annotated tag. The IDs equal the book's.

**Step 1: what a consumer gets for `@v1` today.**

```bash
git ls-remote --tags hosting/report-size.git
```

`git ls-remote` is 🟢 SAFE: it reads. `v1` is an annotated tag: a tag ref that points at a tag object, which in turn names the commit. How many lines will there be, and which one is the commit? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21a/mutable-tag/01-resolve -->
```text
# What a consumer gets for "report-size@v1" today. The line ending in ^{} is the commit.
$ git ls-remote --tags hosting/report-size.git
71c87ced80cd16d0206b29b9a557f2bdf5e3d3b2	refs/tags/v1
80827f43993c0dc6fc8324685d01e720707e5429	refs/tags/v1^{}
```
<!-- /snippet -->

Two lines. The first is the tag object, `71c87ce`. The second, ending in `^{}`, is the commit it points at: `80827f4`. That commit is what a workflow saying `@v1` runs today.

**Step 2: someone with push access moves the tag.**

```bash
git tag -f -a v1 -m "report-size v1"
git push --force origin v1
```

`git tag -f` is 🟡 CAUTION: it moves a local tag, and a tag has no reflog.

`git push --force` of a tag is 🔴 DANGEROUS, so the five answers before it runs. What it changes: the remote tag ref. What it can destroy: it can silently change what every consumer of the tag runs. How to preview: `git ls-remote --tags origin v1`. How to recover: by pushing the old tag object back, if you still have it. When it is appropriate: only for a deliberate "moving major tag" policy that consumers know about.

Here it is run in the sandbox, against a local bare repository, to show you what the other side can do.

<!-- snippet: ch21a/mutable-tag/02-move -->
```text
# Anyone who can push to the action repository can point v1 somewhere else.
$ git tag -f -a v1 -m "report-size v1"
Updated tag 'v1' (was 71c87ce)
$ git push --force origin v1
To $LAB/ch21a/mutable-tag/hosting/report-size.git
 + 71c87ce...0ca190d v1 -> v1 (forced update)
```
<!-- /snippet -->

"Updated tag v1, was `71c87ce`". And the push reports a forced update, with a plus sign: from `71c87ce` to `0ca190d`. In the scenario, the person at this keyboard is a maintainer, or whoever holds a maintainer's token.

**Step 3: the same question again.**

```bash
git ls-remote --tags hosting/report-size.git
```

The name is the same. What do you expect on the two lines? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21a/mutable-tag/03-after -->
```text
# Same name, different commit. No consumer workflow changed.
$ git ls-remote --tags hosting/report-size.git
0ca190da3c6db48b75af6a358aef5b189725e9a4	refs/tags/v1
5de1e2d145bc0b3fbb28e6d457f7220359d63f84	refs/tags/v1^{}

# The commit that was reviewed still exists, and its ID still names exactly that content.
$ git -C hosting/report-size.git cat-file -p 80827f43993c0dc6fc8324685d01e720707e5429:action.yml
name: report-size
description: Prints the size of the build output
runs:
  using: composite
  steps:
    - run: du -sh dist
      shell: bash
```
<!-- /snippet -->

A new tag object, `0ca190d`, and a new commit, `5de1e2d`. Same name, different commit. No consumer workflow changed. A workflow that says `@v1` now runs `5de1e2d`.

Then the second half of the snippet. `git cat-file -p` with the old commit's full ID and the path of `action.yml`. The commit that was reviewed still exists, and its ID still names exactly that content. A workflow pinned to that ID runs what it ran yesterday. There's the promise from the opening: the one form of the line that doesn't change.

**[ON SCREEN]** The state table of section 21A.7 for the two commands. For `git tag -f -a v1`: working tree, index, HEAD and the current branch unchanged; `refs/tags/v1` points at a new tag object; remote unchanged; GitHub unchanged. For `git push --force origin v1`: everything local unchanged; on the remote, `refs/tags/v1` is replaced; and on GitHub, every `@v1` reference resolves to the new commit on its next run.

**[ON SCREEN]** `workflows/12-secure.yml`, then `workflows/ACTION_PINS.md`.

Now how the course records pins. In workflow 12, find the checkout step. The comment above it says: full commit SHA, version as a comment, the format Dependabot maintains. The line itself is the action, an at sign, forty characters, and the version after a hash sign. Every `uses` line in the file has that form: checkout, the uv setup action, the dependency review action, and the cloud credentials action.

In the pin file, each action has one row: the name, the version, the commit ID. The header says when the pins were read and how. Read versions from that file, on the day, and re-verify a pin with the command the file gives before you trust it.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Treating `@v4` as a version.** Root cause: it is a tag, resolved again on every run, and a tag can be moved or deleted by whoever can push to the action's repository.
2. **Taking the commit ID from a fork of the action.** Root cause: the pin is only as good as its source; the documentation says to verify that the ID is from the action's repository and not a repository fork.
3. **Pinning and then never updating.** Root cause: pins do not update themselves, and Dependabot creates no vulnerability alerts for actions pinned to commit IDs.
4. **Approving a pin update without reading its diff.** Root cause: a pin does not protect against a malicious commit pinned deliberately.
5. **Believing a pinned workflow has no unpinned code.** Root cause: actions nested inside composite actions, and scripts fetched in `run` steps, are outside the pin.

## PRODUCTION EXAMPLE

Now, out of the lab. An ML platform organization with sixty repositories decides to pin. Asking sixty teams to remember is the first idea, and the textbook's sentence about policies describes why it won't hold: you want the rule moved from "every author must remember" to "the platform refuses".

So the organization does three things. It adds the `github-actions` ecosystem to the Dependabot configuration of every repository, so that pins have a source of updates before the rule bites. It converts the existing references, reading each ID from the action's own repository. Then it switches on the policy that requires actions to be pinned to a full-length commit SHA. From that day a workflow with an unpinned action fails.

Two details from the table decide whether the rollout goes smoothly. The policy applies to GitHub's own actions as well, so `actions/checkout` by tag fails too. And reusable workflows can still be referenced by tag, so the central deploy workflow that forty repositories call needs its own discipline: a pinned ref by convention, and code-owner review on the callers.

## PRACTICE EXERCISE

Your turn. Do Exercise 29.5, "What can this token do?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

For each workflow in the exercise, before you compute the token's scopes, list every `uses` line and mark it as pinned or floating. Predict for each floating one what it could do with the token you are about to work out.

The challenge is Exercise 29.8, "A workflow nobody wrote", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q321: "Your team pins every action to a commit. Name three things that this does not protect against."

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer first says, in one sentence, what pinning does protect against, in Git terms. Then it gives three limits that are different in kind, each with its reason: one about the pinned code itself, one about code the pin doesn't reach, and one about what you give up in return for immutability. The follow-up asks how you keep pins current without re-opening the window that pinning closed. Think about who proposes the update, how long it waits, and what a human does before merging it.

## RECAP

Let's land this.

You should now be able to say:

- A `uses` line runs someone else's code with your job's token and secrets, and a tag in it is resolved again on every run.
- A tag is a movable ref; a full commit ID names content that cannot change, and it is the only immutable way to reference an action.
- A pin is the commit ID with the version as a comment, taken from the action's own repository and updated by Dependabot, with a default cooldown of three days.
- Pinning does not vouch for the pinned code, does not cover nested unpinned actions or downloaded scripts, and gives up Dependabot alerts.
- Organization policies can restrict which actions run and require pinning; reviewing the workflow files still needs code owners and a ruleset.

## HOMEWORK

Read sections 21A.7 and 21A.8 of [Chapter 21A](../../textbook/ch21a-actions-security.md).

Today you moved a tag with three commands and watched a commit ID stay exactly where it was. Replay that demo once in the lab. Next time: secrets, and why masking isn't a boundary. Until then, look at the state first and type second. See you in the next one.

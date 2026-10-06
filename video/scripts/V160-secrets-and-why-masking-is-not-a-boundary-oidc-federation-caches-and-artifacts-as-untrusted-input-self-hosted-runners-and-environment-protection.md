# V160: Secrets and why masking is not a boundary, OIDC federation, caches and artifacts as untrusted input, self-hosted runners, and environment protection

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 28
- **Prerequisites.** V149, V159
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), sections 21A.9 to 21A.13
- **Demo scripts.** `labs/ch21a/lab-29-2-controls.sh`; the file [`workflows/12-secure.yml`](../../workflows/12-secure.yml); a screen walkthrough of Lab 29.2 in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md)

## HOOK

**[ON SCREEN]** Three sentences a team says about its pipeline.

"Our secrets are safe. They are masked in the logs."

"We do not store cloud keys any more. We use OIDC."

"Our release job has `contents: read`. It cannot be tampered with."

Teams say each of these in good faith, and the incidents of this part show where each belief ends. Masking edits log lines. It does nothing about a process that sends the value somewhere else. OIDC removes the stored key. Any code in the job can still ask for the token. And a read-only job token didn't stop a cache from being written, because cache writes didn't use that token.

None of the three statements is false. Each is true about a narrower thing than the speaker thinks. This video draws the real boundary for each. Keep the third one in mind, the read-only release job. Its answer is the least expected, and it comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You've now seen four of the five parts of the model, and the fifth in the last video. This video is about what a job holds and what it takes in: the things an attacker wants, and the less obvious roads to them.

Four words first. A job is a list of steps that run on one machine, the runner. A secret is an encrypted value stored in GitHub's settings. Masking means that GitHub replaces a secret's value with stars in the log. And OIDC is a way for a job to prove what it is, in place of a stored key.

Five topics, in the order of sections 21A.9 to 21A.13. Secrets: scope, and why masking isn't a boundary. OIDC federation: what `id-token: write` grants and where the access decision is made. Caches and artifacts as untrusted input. Self-hosted runners, from the security side. And environment protection, which you configured in video 149 and now read as a security control.

The demonstration removes two controls from the course's secure workflow and shows which check notices. It's `grep` and `sed` on a file in the sandbox: one command finds lines, the other edits them. Nothing runs on GitHub.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say who can read a repository, environment and organization secret and when;
- explain why log masking does not protect a secret;
- explain what `id-token: write` grants and where the access decision is made;
- explain how a cache or an artifact written by a less trusted run can reach a privileged one;
- state why self-hosted runners and public repositories are a dangerous combination.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**Secrets. In one sentence:** a secret is as exposed as the least trustworthy code in any job that receives it.

**Precisely.** Secrets exist at organization, repository and environment level. And GitHub Actions can only read a secret if you explicitly include the secret in a workflow. Where you include it sets the exposure.

**[ON SCREEN]** The unsafe and the safe form of section 21A.9.

```yaml
# Unsafe: every step of every job, including third-party actions and your dependencies'
# install scripts, has the token in its environment.
env:
  DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}

jobs:
  lint: ...
  test: ...
  deploy: ...
```

```yaml
# Safe: one step of one job, behind an environment.
jobs:
  deploy:
    environment:
      name: staging
    steps:
      - name: Deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
        run: bash scripts/deploy.sh staging
```

In the first form the secret is in workflow-level `env`, the environment variables that every step receives. The lint job has it. The test job has it, and so does every package whose install script or test runs there. In the second form, one step of one job has it, and that job is behind an environment, a named gate the job must pass first. You saw the first form in the inventory of video 156: a secret named on line 19 of a file, before any job.

Two facts are routinely misunderstood.

**Write access is secret access.** The documentation: "Any user with write access to your repository has read access to all secrets configured in your repository." The reason: they can push a branch with a workflow that uses them. The textbook says two of the case studies are this sentence at scale. And it names the exception: environment secrets behind required reviewers make the sentence false for your most valuable credentials.

**Masking is a courtesy for logs.** Registered secrets are redacted from logs. But the documentation says: "because there are multiple ways a secret value can be transformed, this redaction is not guaranteed". It adds: "never use structured data as a secret". And: "if an unredacted secret is sent to a workflow run log, you should delete the log and rotate the secret".

Redaction matches known strings in log output. It does nothing about a process that sends the value elsewhere, and nothing about code that reads the runner's memory, which the Phase 0 report finds recurring across the incidents. The textbook's conclusion is the sentence to remember: the boundary is which code runs in the job and which secrets the job holds.

**OIDC federation. In one sentence:** instead of storing a cloud key as a secret, the job asks GitHub for a signed statement of what it is, and the cloud exchanges that statement for a credential valid for that job only.

**Precisely.** The job or workflow must grant the `id-token: write` permission to allow GitHub's OIDC provider to create a JSON Web Token, a small signed document. And the documentation is exact about what the permission is: it "only enables fetching and setting the OIDC token; it does not grant write access to other resources". The cloud returns a short-lived access token that is only valid for a single job.

The token's claims describe the run. A claim is one stated fact inside the token. Besides the standard ones there are the repository and its ID, the owner and its ID, the visibility, the ref and its type, the environment, the event name, the workflow reference, the runner environment, the actor, and others. The cloud's trust policy matches on them, above all on the subject, the claim that says which repository, and which branch or environment, is asking.

**[ON SCREEN]** The subject table of section 21A.10.

For a job that references an environment, the default subject is the repository followed by `environment` and the environment's name. For a pull request event with no environment: the repository and `pull_request`. For a branch: the repository and the full branch ref. For a tag: the repository and the full tag ref.

Quick quiz. Where is the access decision made? A, at GitHub, when it signs the token. B, at the cloud provider, when it reads the token. Your answer?

**[PAUSE]**

B. Not at GitHub. GitHub states facts. The cloud provider decides, by comparing those facts with its trust policy, its own list of conditions. The OIDC reference: "You must define at least one condition, so that untrusted repositories can't request access tokens for your cloud resources." The textbook: the trust policy is where the security lives.

GitHub's guide for one cloud gives a condition that requires the audience and the exact subject of one environment in one repository. The same guide also shows a wildcard form: the repository followed by a star. The textbook tells you how to read that one: every branch, every tag and every pull request workflow of the repository may assume the role. Prefer the exact form.

**[ON SCREEN]** Callout: Version note.

Older behavior: the subject contains only names, so a deleted and re-registered organization or repository name could mint the same subject. Current behavior: repositories created after the fifteenth of July 2026 use an immutable default subject format that includes both the owner ID and the repository ID. Renames and transfers after that date switch as well, and existing repositories can opt in. Since: opt-in on the twenty-third of April 2026, default on the fifteenth of July 2026. Recommended: check which format your repository issues before writing the trust policy. A policy in the old format won't match a new repository.

Subject customization lets an organization or repository change which claims form the subject, for example to require the reusable workflow reference, so that only a particular reusable workflow can obtain the role.

**What OIDC does not do.** It removes the long-lived key. It doesn't make the job trustworthy. The textbook quotes a post-mortem, a team's published account of its incident: "OIDC trusted-publisher binding has no per-publish review. Once configured, any code path in the workflow can mint a publish-capable token." So the rule has three parts. Grant `id-token: write` to one job. Bind the subject to an environment with protection rules. And let no untrusted code or cache into that job.

**Caches and artifacts. In one sentence:** a cache is a shared, unsigned directory keyed by a string. Whoever can write an entry under the key your release job computes controls what that job restores.

**Precisely.** The documentation: "Anyone with read access can create a pull request on a repository and access the contents of a cache", and "cache contents are not signed or verified". A run can restore caches from its own branch and from the default branch. A `pull_request` run saves to its own merge ref, which other branches can't restore. A privileged trigger runs in the default branch's context, and that was the opening. The post-mortem records: "cache writes use a runner-internal token, not the workflow `GITHUB_TOKEN`… Setting `permissions: contents: read` does not block cache mutation."

That's the third sentence of the hook, answered. The read-only job token was never the token that writes the cache. Two platform changes followed.

The twenty-sixth of June 2026: only `push`, `workflow_dispatch`, `repository_dispatch`, `delete`, `registry_package`, `page_build` and `schedule` can create or overwrite caches in the default branch's scope. Other triggers that resolve to it get read-only access.

The tenth of September 2026: `cache-mode`, at workflow or job level, with the values `read`, `write`, `write-only` and `none`. The job value overrides the workflow value. And a warning from the changelog: explicitly declaring `write` or `write-only` on a low-trust trigger reintroduces the risk of cache poisoning.

```yaml
jobs:
  publish:
    cache-mode: none      # a job that holds a publishing identity restores nothing it did not build
```

Setup actions cache implicitly, so check them too. And artifacts, the files one job uploads for another to download, follow the same rule. The documentation: "A `workflow_run` workflow should treat artifacts uploaded by other workflows as untrusted data, since their contents can come from a fork."

**Self-hosted runners. In one sentence:** a self-hosted runner is your machine, on your network, executing whatever the workflow says, and it keeps its state between jobs unless you make it ephemeral.

The documentation: "Self-hosted runners should almost never be used for public repositories on GitHub, because any user can open pull requests against the repository and compromise the environment." Private repositories aren't exempt: anyone who can fork the repository and open a pull request, generally those with read access, can do the same. GitHub-hosted runners are "ephemeral and clean isolated virtual machines". Self-hosted ones "can be persistently compromised by untrusted code in a workflow".

The fork approval gate doesn't help once a contributor is past it. And on self-hosted runners, environments don't isolate secrets.

The documented controls. Ephemeral runners that take one job and are removed. Runner groups that restrict which repositories may use a runner. The organization setting that restricts or disables repository-level runners. And approval for all external contributors.

**Environment protection. In one sentence:** an environment puts a human decision, a branch condition, or both between a job and the secrets and cloud identity that belong to a deployment target.

You know the mechanics from video 149. For security review three details matter. Referencing a name that doesn't exist creates an environment with no rules: a typing error in the name silently removes the gate. Deployment branch rules are evaluated against the ref the run executes on: since the eighth of December 2025 that is the merge ref for `pull_request` events and the default branch for `pull_request_target`. And required reviewers and wait timers are plan-gated, meaning they depend on your GitHub plan: on Free, Pro and Team they exist only for public repositories.

And the combination that makes the whole design hold: with OIDC, an environment name in the subject means the cloud role can be assumed only by a job that passed that environment's rules.

## MENTAL MODEL

**Analogy for OIDC,** from the textbook. A notarized letter of introduction in place of a copied house key. The cloud reads the letter, which names the repository, the branch and the environment, and decides whether to open.

The analogy breaks at one point: any code running in the job can ask the notary for the letter.

Take that sentence seriously and the three topics of this video become one. A secret in the environment, an OIDC token on request, the job token: all of them are available to every piece of code that runs in the job. Masking doesn't change that. Short lifetimes don't change that. A read-only job token doesn't change that for the other two.

So there are only two real levers. What the job holds: as little as possible, in as few jobs as possible, behind a gate. And what code and input reach the job: no outsider's code, no cache it didn't build, no artifact it treats as anything but data.

That's the question from video 156 again, now with a full answer to its third part: "what can the job reach" includes what the job can ask for.

## DIAGRAM

Try it now, thirty seconds, on paper. Draw a job as a box with three steps: your script, a third-party action, and a dependency's install script. The job holds one secret in `env`. Mark every step that can read it, and say the number out loud.

**[PAUSE]**

**[DIAGRAM]** Two pictures side by side. On the left, a job with a secret and three steps. Draw the three steps, then the secret available to all three, then the arrow from the third step outward. On the right, the OIDC exchange, one arrow at a time.

```text
  A JOB THAT HOLDS A SECRET                         THE OIDC EXCHANGE

  +------------------------------------+            job (permissions: id-token: write)
  | job    env: TOKEN = ****           |              |
  |                                    |              | 1. asks GitHub's OIDC provider for a token
  |  step 1  your script        TOKEN  |              v
  |  step 2  a third-party      TOKEN  |            signed token with claims:
  |          action                    |              repository, ref, environment, event, ...
  |  step 3  a dependency's     TOKEN -+--> anywhere  sub = repo:ORG/REPO:environment:NAME
  |          install script            |    on the    |
  +------------------------------------+    network   | 2. presents it to the cloud provider
                                                      v
   the log shows ****                               trust policy: conditions on aud and sub
   the value left through step 3                      |    <-- THE ACCESS DECISION IS MADE HERE
                                                      | 3. if the conditions match
   masking edits log lines;                           v
   it is not a boundary                             short-lived credential, valid for this job only
```

All three. On the left, the mask and the leak are unrelated: the log shows stars, and the value left through step three. On the right, the only place where "no" can be said is the trust policy. If its condition is a wildcard, it says yes to every branch and every pull request workflow of the repository.

**[DIAGRAM]** On the left, the mask and the leak are unrelated. On the right, the only place where "no" can be said is the trust policy. If its condition is a wildcard, it says yes to every branch and every pull request workflow of the repository.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21a/lab-29-2-controls`. It works on a sandbox copy of workflow 12. The commands are `grep`, `sed` and `git` on one file. Nothing is executed on GitHub.

**Step 1: the baseline.**

```bash
git status --short
grep -c 'uses:' .github/workflows/12-secure.yml
grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
```

Two checks that a team could run in CI, its automated checks on every change. The first lists every `uses` line that isn't pinned to forty hexadecimal characters. The second counts the checkouts that don't leave the credential on disk. On an intact workflow 12, what does each print? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21a/lab-29-2-controls/01-baseline -->
```text
$ git status --short
$ grep -c 'uses:' .github/workflows/12-secure.yml
6
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
4
```
<!-- /snippet -->

A clean working tree. Six `uses` lines. The unpinned scan returns nothing, with exit status 1 from `grep`: every action is pinned. And four lines with `persist-credentials: false`.

**Step 2: a "cleanup" that many reviewers would approve.**

```bash
sed -i.bak -e 's/@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1/@v7/' -e '/persist-credentials: false/d' .github/workflows/12-secure.yml
git diff --stat
```

The comment in the transcript describes it the way its author would: readable version tags, less boilerplate. The `sed` command edits a file in the working tree. Git has recorded nothing yet.

<!-- snippet: ch21a/lab-29-2-controls/02-break -->
```text
# A "cleanup" that many reviewers would approve: readable version tags, less boilerplate.
$ sed -i.bak -e 's/@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1/@v7/' -e '/persist-credentials: false/d' .github/workflows/12-secure.yml
$ rm .github/workflows/12-secure.yml.bak
$ git diff --stat
 .github/workflows/12-secure.yml | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)
```
<!-- /snippet -->

Three insertions, seven deletions. Imagine this diff in a pull request titled "Tidy the CI file". It is shorter. It is more readable. Nothing about it looks like a security change. Two controls are gone.

**Step 3: which check notices.**

<!-- snippet: ch21a/lab-29-2-controls/03-detect -->
```text
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
36:        uses: actions/checkout@v7
82:        uses: actions/checkout@v7
111:        uses: actions/checkout@v7
[exit status: 0]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
0
[exit status: 1]
```
<!-- /snippet -->

The unpinned scan now prints three lines, 36, 82 and 111, each a checkout by tag, with exit status 0: found. And the count of `persist-credentials: false` is zero. Both checks noticed. A reviewer reading the diff might not have.

Now the limit of this demonstration, which the lab's objective states: you remove two controls and see which checks notice. These two can be found by pattern. Workflow 12 marks nine controls with comments. Ask yourself which of the others a `grep` could detect if removed, and which only a person would catch. Removing `cache-mode: none` from the deploy job? Removing the `environment` block? Changing the `if` that keeps pull requests out of the deploy job? That question is the lab.

**Step 4: recover.**

```bash
git restore .github/workflows/12-secure.yml
```

`git restore` on a path is 🔴 DANGEROUS, so the five answers. What it changes: the file in the working tree, back to the version in the index. What it can destroy: uncommitted edits to that file that were never staged. How to preview: `git diff` for the path, which you saw as a stat. How to recover: none for content that was never staged. When it is appropriate: here, because the edit was the experiment, and discarding it is the goal.

<!-- snippet: ch21a/lab-29-2-controls/04-recover -->
```text
$ git restore .github/workflows/12-secure.yml
$ git status --short
$ grep -n 'uses:' .github/workflows/12-secure.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ grep -c 'persist-credentials: false' .github/workflows/12-secure.yml
4
```
<!-- /snippet -->

Clean status, the scan is empty again, and the count is back to four.

**[ANIMATION]** trees: file=.github/workflows/12-secure.yml versions=the_committed_file,the_cleanup steps=setup,edit,restore title=What_the_restore_did

One picture of what happened. The cleanup edited the file in the working tree only. Nothing was staged, and nothing was committed. So restore had one job: copy the version in the index back over the edit.

**[ON SCREEN]** Lower third: GitHub Actions. `workflows/12-secure.yml`, the `deploy-staging` job, then a screen walkthrough.

Read the deploy job with this video's five topics. Its `if` admits only a push to `main`: only trusted code reaches this job. It names an environment: the protection rules, and the environment's name in the OIDC subject. Its `permissions` are `contents: read` and `id-token: write`: the only job that may request an OIDC token. `cache-mode: none`: it neither restores nor saves a cache. And there is no stored cloud key anywhere in the file: the role is assumed with a short-lived token. Search the whole file for the `secrets` context. It doesn't occur.

Now Lab 29.2, Part B, on your practice repository, in your normal shell. The interface changes. The lab text and the linked documentation are the reference. No GitHub output was captured by the authors.

Add the workflow through a pull request and look at the list of checks. Predict first which jobs run for a pull request and which are skipped, from their `if` conditions. The deploy job is skipped for two reasons at once. Name both. Then the lab has you make the title job fail on purpose by editing the title. Notice what the lab tells you: editing the title doesn't start a new run, because the trigger without `types` reacts to opened, synchronize and reopened. You push an empty commit to start one, read the failed job, restore the title, and push again.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Putting a secret in workflow-level `env`.** Root cause: every step of every job, including third-party actions and dependencies' install scripts, then has it in its environment.
2. **Treating log masking as protection.** Root cause: redaction matches known strings in log output; it does nothing about a process that sends the value elsewhere.
3. **A wildcard subject in the cloud's trust policy.** Root cause: it lets every branch, every tag and every pull request workflow of the repository assume the role; the trust policy is where the access decision is made.
4. **Letting a job with a publishing identity restore a cache.** Root cause: cache contents are not signed, and a less trusted run may have written the entry under the key the job computes.
5. **Believing `permissions: contents: read` protects the cache.** Root cause: cache writes used a runner-internal token, not the job token.

## PRODUCTION EXAMPLE

Now, out of the lab. Picture a team that publishes an evaluation library to a package registry. Two years ago it stored a registry token as a repository secret. Last year it moved to trusted publishing with OIDC and deleted the stored token, and wrote in its security notes that publishing credentials can no longer leak.

Review that with this video. The stored key is gone: good, nothing long-lived to steal. But which job has `id-token: write`? If it's set at workflow level, every job can request the token, including the test job that runs the dependencies' code. Is the publishing job behind an environment with rules, and is the environment's name in the subject the registry checks? Does the publishing job restore a cache, and which runs can write under that key? Does any step in it run code that didn't come from a reviewed commit on `main`?

The textbook's summary of what OIDC changes fits on one line: it removes the long-lived key, and it doesn't make the job trustworthy. The team's notes should say which job can ask for the identity, what gates that job, and what is allowed into it.

## PRACTICE EXERCISE

Your turn. Do Lab 29.2, "Justify every control of workflow 12", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md). Part A runs in `labs/shell`.

Write the table the lab asks for: control, line, threat, and what breaks without it. The file marks nine controls with comments. Find at least two more that have no comment. For each control, predict before you test whether a pattern scan would notice its removal.

The challenge is Exercise 29.6, "Who can assume the role?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q313: "What does `id-token: write` grant, and where is the access decision made?"

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer is precise about the permission: what it enables and what it explicitly doesn't. It then follows the exchange: what the token states, who reads it, and what is compared with what. It names the claim that matters most and gives the difference between an exact and a wildcard condition in terms of who can assume the role. It ends with what federation doesn't solve. The follow-up is a trust policy that matches for older repositories and not for one created this summer. You heard the version note, so say what changed and how you would diagnose it.

## RECAP

Let's land this.

You should now be able to say:

- A secret is as exposed as the least trustworthy code in any job that receives it; write access to the repository is access to its secrets, except environment secrets behind required reviewers.
- Masking edits log lines; the boundary is which code runs in the job and which secrets the job holds.
- `id-token: write` only lets the job fetch an OIDC token; the cloud's trust policy makes the access decision, mostly on the subject.
- Caches are shared and unsigned, artifacts from other workflows can come from a fork; a job with an identity uses `cache-mode: none` and treats artifacts as data.
- A persistent self-hosted runner keeps what a job left, and an environment puts its gate in front of the job.

## HOMEWORK

Read sections 21A.9 to 21A.13 of [Chapter 21A](../../textbook/ch21a-actions-security.md).

Today you drew the real boundary behind three comfortable sentences, and watched two controls vanish in a tidy-looking diff. Run that demo yourself in the lab shell. Next time: static analysis of workflows, the platform changes of 2025 and 2026, and workflow 12. Until then, look at the state first and type second. See you in the next one.

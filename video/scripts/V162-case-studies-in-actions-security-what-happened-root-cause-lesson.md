# V162: Case studies in Actions security: what happened, root cause, lesson

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 20
- **Prerequisites.** V161
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), section 21A.18
- **Demo scripts.** `labs/ch21a/mutable-tag.sh` (snippets `move`, `after`), as the local model of the first pattern. Everything else is a walk through the table of section 21A.18 with its source links on screen.

## HOOK

**[ON SCREEN]** The sentence from the start of this part: "No password was stolen. How?"

On the eleventh of May 2026, 84 malicious versions of 42 packages were published through a project's own trusted-publisher identity. No registry token was stolen. The project had read-only workflow permissions. It published through OIDC. By the standards of most checklists, it had followed best practice.

You now know every mechanism that was involved. A privileged trigger. A build of fork code. A shared cache. A release job that restored it. An identity that any code in the job could ask for. In this video you put the links in order, for this case and seven others, and for each you name the control that would have broken the chain. Hold on to the question on screen. You'll answer it yourself, link by link.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is a walk through one table: the case studies of section 21A.18. Each case is given in the same three parts: what happened, root cause, lesson. The cases come from the Phase 0 report and its sources, and every row has a source link, which is on screen while I talk about it.

A reminder of five words from this part. A workflow is a file that tells GitHub Actions which jobs to run. A tag is a movable name for a commit, and pinning means naming the commit ID instead. A privileged trigger is an event whose run holds the repository's token and secrets. A cache is a stored directory that a later run can restore. And OIDC gives a job a short-lived credential in place of a stored key.

Three rules for this video, and they're the textbook's rules.

No attack detail beyond the published summaries is reproduced. This is a defensive course.

Dates and figures are quoted only as the cited sources give them. Where the sources disagree, I say so. The table has a column called "Flags" for exactly that, and I read the flag aloud for every row.

And no embellishment. You'll use these cases to argue for controls in design reviews. An argument that rests on an exaggerated number fails the first time someone checks it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- retell each case of the section as what happened, root cause and lesson, with its flags;
- assign each case to one of the recurring patterns;
- name the control from this part that would have broken each chain;
- trace how a fork pull request led to a publish without any stored credential being stolen;
- quote dates and figures only as the cited sources give them.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions. The table of section 21A.18, one row at a time, with the source links visible.

**tj-actions/changed-files, March 2025.** Sources: the CISA alert and the GitHub advisory.

What happened: version tags were repointed to a malicious commit that printed secrets from runner memory into workflow logs. More than 23,000 repositories used the action.

Root cause: a stolen bot token. The chain began with a `pull_request_target` flaw in an upstream project, according to the Unit 42 write-up.

Lesson: tags are mutable. Only commit-pinned workflows were unaffected. And public logs are world-readable.

Quick quiz. You retell this case in a design review. Which sentence do the sources support? A, more than 23,000 repositories leaked secrets. B, more than 23,000 repositories used the action. Your answer?

**[PAUSE]**

B, and the flags explain it. Flags: there is a conflict about the time window. CISA gives it as the twelfth of March at midnight UTC to the fifteenth of March at noon UTC, 2025. The advisory says the fourteenth to the fifteenth of March. Unit 42 places the mass tag override on the fourteenth of March at sixteen fifty-seven UTC. The textbook's instruction: use CISA's window for audits. And how many repositories leaked secrets is not stated by either source. A figure of "218 repositories" is secondary and unverified. So when you tell this case, say "more than 23,000 repositories used the action". Don't say that number leaked.

**Nx, "s1ngularity", August 2025.** Source: the project's post-mortem.

What happened: malicious versions of eight packages were live for about four hours and harvested developer credentials.

Root cause, in three parts. A `pull_request_target` workflow that echoed an unsanitised pull request title. A legacy read-write default token. And a publish workflow that could be dispatched.

Lesson: one injectable line plus a write token reaches a publish credential.

Flags: none.

Map the three causes to three videos. The echoed title is video 158. The legacy default token is video 156: a repository created before the default changed. And the dispatch is the documented exception from video 156: events from the job token start no runs, except `workflow_dispatch` and `repository_dispatch`.

**GhostAction, September 2025.** Source: GitGuardian.

What happened: compromised maintainer accounts pushed a workflow that sent secrets to an attacker's server: 3,325 secrets from 817 repositories.

Root cause: write access equals secret access.

Lesson: protect workflow files with code-owner review, and prefer environment-scoped secrets and OIDC.

Flag: this is a vendor report.

**Shai-Hulud and its sequel, September and November 2025.** Sources: the GitHub Blog and Wiz.

What happened: a self-replicating npm worm stole tokens, pushed secret-dumping workflows, and in its second wave registered infected machines as self-hosted runners.

Root cause: stolen developer and CI tokens.

Lesson: a token with workflow write access is equivalent to every secret it can reach. Monitor for new workflows, runners and repositories.

Flag: the size of the second wave is approximate. The notes cite the same Wiz post for about 700 malicious versions and about 800 packages.

**PyTorch runners, disclosed January 2024, and Ultralytics, December 2024.** Sources: a researcher write-up and the PyPI blog.

What happened: persistent self-hosted runners, machines the project operated itself, on a public ML repository could be reached by a pull request. And, in the second case, a poisoned Actions cache led to malicious PyPI releases published through the legitimate workflow.

Root cause: self-hosted runners with weak approval settings, and an insecure trigger plus cache trust.

Lesson: ML projects are prime targets. Use ephemeral runners and treat caches as untrusted.

Flag: PyTorch is a researcher disclosure, not an observed attack. Say "could be reached", not "was attacked".

**Trivy and LiteLLM, February to March 2026.** Sources: the advisory, the vendor's notice, and Datadog.

What happened: a `pull_request_target` flaw leaked a token. Weeks later a malicious scanner release was published and almost all action tags were force-pushed to malicious commits. A downstream LLM gateway library that ran the scanner unpinned had its publishing credential stolen, and two malicious versions were on PyPI for about three hours.

Root cause: incomplete, non-atomic credential rotation after the first incident, meaning the credentials weren't all replaced at once. And tag-pinned security tooling.

Lesson: rotate everything at once. Security tools in CI are high-value targets. Pin by commit.

Flags: a conflict in the count of tags: 75 of 76 according to Wiz, 76 of 77 according to Datadog. And write-ups name the account behind the first exploit differently. Use the advisory and the vendor notice for exact figures. That's why I said "almost all".

**TanStack, 11 May 2026.** Source: the project's post-mortem.

What happened: 84 malicious versions of 42 packages were published through the project's own trusted-publisher identity. No npm token was stolen.

Root cause, as a chain. A `pull_request_target` workflow built fork code. The fork poisoned the shared cache. The release job restored it. Malware read the job's OIDC token from runner memory.

Lesson: read-only `permissions` didn't block cache writes. OIDC isn't safe if untrusted code runs in the job. And `pull_request_target` bypassed the first-time-contributor gate.

Flags: whether the versions carried valid provenance attestations, and the name "Mini Shai-Hulud", come from secondary reports. The post-mortem does not say so. And no GitHub-authored post-mortem was found.

**Codecov, 2021.** Source: Codecov's security update.

What happened: a modified uploader script exported CI environment variables for two months.

Root cause: a mutable script fetched and executed in CI.

Lesson: remote scripts are the same risk class as mutable tags.

Flag: history only.

And one sentence of completeness from the textbook. A further tag hijack, of the actions-cool actions in May 2026, is known to the course only through secondary reporting. It is mentioned for completeness and nothing is built on it.

**Three recurring patterns.**

One: mutable references were repointed after a maintainer credential was stolen. tj-actions and Trivy.

Two: a privileged trigger ran or interpolated outsider input. The upstream of tj-actions, Nx, Trivy, and TanStack.

Three: stolen tokens were used to push workflows. GhostAction and Shai-Hulud.

And one technique recurs across them: reading the runner process's memory to collect secrets and OIDC tokens.

The report's conclusion is the sentence to carry into a design review. Masked logs are irrelevant once attacker code runs in a job. Then the quotation: "the robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds."

## MENTAL MODEL

A picture helps. Think of each incident as a chain, and of each control as a pair of cutters.

A chain needs every link. The TanStack chain, as the post-mortem gives it, has four. A privileged workflow builds fork code. The fork writes into the shared cache. The release job restores that cache. Code in the release job reads the job's OIDC token. There's the answer to "No password was stolen. How?" Four links, and none of them is a stolen password.

Try it now, thirty seconds, on paper. Write the four links as a chain, top to bottom. Then take the controls from this part and write each beside the link it cuts. Say them out loud.

**[PAUSE]**

Not using `pull_request_target` for a build, or not running the fork's code under it: cuts link one. That's video 157, and the checkout action's refusal since version 7 leans on the same link.

A read-only default-branch cache for low-trust triggers: cuts link two. That's the platform change of the twenty-sixth of June 2026.

`cache-mode: none` on the job that holds an identity: cuts link three. That's video 160 and workflow 12.

Binding the identity to an environment with protection rules, and letting no untrusted code or cache into that job: addresses link four. Note the word. Once attacker code is running inside a job that may request the token, nothing in the job stops the request. Link four is cut by cutting the earlier ones.

Where this model breaks: it suggests one cut is enough. For one chain, it is. But you don't know in advance which chain will be tried, and several of these projects were hit through a combination nobody had drawn. That's why the controls are layered, and why section 21A.21 says to review workflows as a set.

## DIAGRAM

**[DIAGRAM]** Three columns, one per recurring pattern. Write the pattern as the column heading, then place each case under the pattern or patterns it shows. Under each column write the control from this part that answers it.

```text
  PATTERN 1                        PATTERN 2                          PATTERN 3
  mutable references repointed     a privileged trigger ran or        stolen tokens used to
  after a maintainer credential    interpolated outsider input        push workflows
  was stolen
  -----------------------------    -------------------------------    ---------------------------
  tj-actions (March 2025)          upstream of tj-actions             GhostAction (Sept 2025)
  Trivy (Feb to March 2026)        Nx (August 2025)                   Shai-Hulud (Sept, Nov 2025)
                                   Trivy (Feb to March 2026)
  same risk class:                 TanStack (11 May 2026)
  Codecov (2021), a mutable        related: Ultralytics (Dec 2024),
  script fetched in CI             an insecure trigger plus cache
                                   trust
  -----------------------------    -------------------------------    ---------------------------
  control: pin by commit ID;       control: no fork code in a         control: code-owner review
  no remote script piped into      privileged job; untrusted text     on workflow files;
  a shell; rotate everything       only through env; read-only        environment-scoped secrets
  at once after an incident        token; cache-mode none             and OIDC; monitor for new
                                                                      workflows and runners

  one technique across all three: reading the runner process's memory for secrets and OIDC tokens
  => masked logs are irrelevant once attacker code runs in a job
```

**[DIAGRAM]** Trivy appears in two columns, and that is the lesson of that case: the first incident was pattern two, and because the rotation afterwards was incomplete, the second was pattern one. The placement of Codecov and Ultralytics beside the patterns follows the lessons the table gives for them; the textbook's own sentence lists the six cases in the three patterns.

Read the columns. Trivy appears in two of them, and that's the lesson of that case: the first incident was pattern two, and because the rotation afterwards was incomplete, the second was pattern one.

## LIVE TERMINAL DEMO

**[TERMINAL]** One replay, once more: `labs/run ch21a/mutable-tag`. It is the local model of the first pattern. A bare repository plays the action's repository. This is Git in the sandbox; it shows the mechanism that the tj-actions and Trivy rows describe as "tags were repointed" and "force-pushed", and nothing else about those incidents.

**Step 1: the move.**

```bash
git tag -f -a v1 -m "report-size v1"
git push --force origin v1
```

`git tag -f` is 🟡 CAUTION: it moves a local tag. `git push --force` of a tag is 🔴 DANGEROUS. The five answers, as section 21A.7 gives them. What it changes: the remote tag ref. What it can destroy: it can silently change what every consumer of the tag runs. How to preview: `git ls-remote --tags origin v1`. How to recover: push the old tag object back, if you still have it. When it is appropriate: only for a deliberate "moving major tag" policy that consumers know about.

In the first pattern, who is at this keyboard? Read the root-cause column of the tj-actions row again before you answer. Say it out loud.

**[PAUSE]**

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

A forced update of `v1`, from `71c87ce` to `0ca190d`. The person at the keyboard holds a credential that can push to the action's repository. In the incident rows it was a stolen bot token in one case, and credentials that had not been fully rotated in the other. From Git's side, a legitimate maintainer and a thief with the maintainer's token are the same.

**Step 2: what consumers get afterwards.**

```bash
git ls-remote --tags hosting/report-size.git
```

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

The same name, a different commit: `5de1e2d`. No consumer workflow changed. And the commit that was reviewed still exists under its own ID, with exactly its old content.

**[ANIMATION]** graph: 80827f4-5de1e2d main; 80827f4 tag:v1; HEAD=main => 80827f4-5de1e2d main tag:v1; HEAD=main title=Same_name,_different_commit

**[ANIMATION]** step: state-1

Now read the lesson column of the tj-actions row with this on screen: "only commit-pinned workflows were unaffected". You saw why a moment ago.

**[ANIMATION]** step: state-2

A workflow that named the tag ran the new commit on its next run. A workflow that named the old commit's ID ran the old commit.

**[ANIMATION]** end

And you can audit your own exposure with the same reading command, which is 🟢 SAFE: `git ls-remote --tags` against an action's repository shows what each tag points at today. Whether it pointed there last month is something only your pins, or your logs, can tell you.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Quoting a figure that the sources do not support.** Root cause: several rows carry conflicts or secondary figures; for tj-actions the number of repositories that leaked secrets is not stated by the primary sources.
2. **Telling a researcher disclosure as an attack.** Root cause: the PyTorch case is a disclosure, not an observed attack; the flag says so.
3. **Concluding that OIDC or read-only permissions "failed".** Root cause: each did what it is defined to do; the chain went through a cache and through untrusted code inside the job, which neither control addresses.
4. **Rotating one credential after an incident.** Root cause: in the Trivy case, incomplete, non-atomic rotation after the first incident enabled the second.
5. **Arguing for one control per incident.** Root cause: the chains differ, and the edge case behind most of them is two workflows that share something.

## PRODUCTION EXAMPLE

Now, out of the lab. A staff engineer proposes three changes to an ML platform's repositories: require commit pins by policy, forbid `pull_request_target` except for metadata-only jobs, and move publishing credentials behind environments. A director asks why this is worth a week of work, given that "we have never had an incident".

The engineer answers with three rows, one per pattern, and for each row the three parts and the flag. For pins: the tj-actions row, with the sentence "only commit-pinned workflows were unaffected", the figure of more than 23,000 repositories that used the action, and the statement that the number of repositories that leaked secrets is not given by the primary sources. For the trigger: the Nx row, whose flags column says "none", with its three causes. For credentials: the GhostAction row, marked as a vendor report, with its one-line root cause.

The director checks one of the links during the meeting. The numbers match. The proposal is approved. That's what the flags are for.

## PRACTICE EXERCISE

Your turn. Do Exercise 29.2, "The comment workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Before you start, predict which of the three recurring patterns the exercise's workflow belongs to, and which case of the table it most resembles. Afterwards, write the chain for it link by link, and the control that cuts each link.

The challenge is Exercise 29.8, "A workflow nobody wrote", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q332: "In the TanStack incident no credential was stolen from storage. Walk through how a fork pull request led to a publish, and name the control that would have broken each link."

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer gives the chain as numbered links, in the post-mortem's order, and for each link one control with the video's worth of reasoning behind it in a sentence. It is careful about what is sourced: it uses the post-mortem's facts and marks what comes from secondary reports. The follow-up quotes the team: "We had read-only permissions and we publish through OIDC, so we followed best practice." Name the two assumptions in that sentence that the incident disproved. Both are in the lesson column of the row.

## RECAP

Let's land this.

You should now be able to say:

- Each case has three parts, what happened, root cause and lesson, and a flag that says how far its figures can be trusted.
- Three patterns recur: mutable references repointed after a credential theft; a privileged trigger that ran or interpolated outsider input; stolen tokens used to push workflows.
- One technique recurs across them: reading runner memory, which makes masked logs irrelevant once attacker code runs in a job.
- In the TanStack chain no stored credential was stolen: fork code under a privileged trigger, a poisoned shared cache, a release job that restored it, and an OIDC token read from memory.
- The robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds.

## HOMEWORK

Read section 21A.18 of [Chapter 21A](../../textbook/ch21a-actions-security.md) and follow two of its source links to the published post-mortems. Read [`guides/security-guide.md`](../../guides/security-guide.md).

Today you walked through eight incidents with their flags, and cut one chain link by link. Retell one case aloud, with its flag, before the next video. Next time: the Git client, what a clone runs, the three guards, and recursive clones. Until then, look at the state first and type second. See you in the next one.

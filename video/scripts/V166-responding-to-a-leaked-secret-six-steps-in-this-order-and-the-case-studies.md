# V166: Responding to a leaked secret: six steps in this order, and the case studies

- **Part.** 7: Security
- **Module.** 31
- **Planned minutes.** 24
- **Prerequisites.** V165
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.14 and 21B.15
- **Demo scripts.** `labs/ch21b/lab-31-1-tabletop.sh` (snippets `confirm`, `contain`, `assess`), stopping before the eradication steps, which the next two videos teach

## HOOK

**[ON SCREEN]** A message at 09:12: "There is an API key in the repo. It was pushed last week."

What does the team do in the first ten minutes? Decide on your own first move, and say it out loud.

**[PAUSE]**

In most teams, someone opens the repository. They look for the file, discuss whether to delete it or to rewrite history, argue about force pushes, and ask who has a clone. An hour later the history is being rewritten. The key still works.

The cases in this video show what that order costs. A key valid about two months after the first alert. Cloud keys valid 48 hours after the repository was taken down. An organization breached a second time through tokens it had not rotated.

There are six steps, and their order matters more than the tools. The first step is the one that teams under pressure skip. Hold on to your own first move. You'll check it against step one in a moment.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the video that the last three have been preparing. You know what a stolen credential can reach. You know that nothing you do to a repository un-publishes a pushed commit. You know how to measure where a secret is. Now you put those in order, as a response.

Three words first. A secret here is a credential, such as an API key: a string that proves to a service who is asking. The issuer is the service that created it. To revoke a key is to cancel it at the issuer, and to rotate it is to replace it with a new one.

Two sections. Section 21B.14: responding to a leaked secret in six steps: contain, assess, eradicate, recover, communicate, prevent. Section 21B.15: nine case studies, each as exposure, root cause and lesson.

One note on the names. The textbook says the names of the phases follow common incident-response practice. The Phase 0 report did not check them against a cited standard, and legal notification duties are outside this course.

The demonstration replays the first three steps of the tabletop lab, a rehearsal of an incident with nothing real at stake. It stops before eradication. A history rewrite is an operation with its own dangers, and the next two videos teach it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- recite the six steps in order: contain, assess, eradicate, recover, communicate, prevent;
- explain why revocation comes first and why it may be sufficient;
- produce the five facts of an assessment and say which of them Git can answer;
- decide whether a history rewrite is warranted;
- retell two case studies as exposure, root cause and lesson, quoting figures as the cited sources give them.

## CONCEPT

**[ON SCREEN]** The table of section 21B.14, one step at a time.

**Step 1: contain.** Revoke or rotate the credential first. Was that your first move? The sources, GitHub and OWASP, add: that alone may be sufficient, and a history rewrite may not be warranted.

The evidence of what goes wrong otherwise. An xAI key valid about two months after the first alert. A contractor's AWS keys valid 48 hours after the repository was taken down. And the Internet Archive, breached a second time through tokens it had not rotated.

**Step 2: assess.** Identify the secret, its owner, and what it can reach. Check validity status and exposure labels. Review GitHub audit logs and the provider's logs for use. And include forks, deleted forks and force-pushed commits in scope.

What goes wrong otherwise: an affected company declined to say whether logs showed third-party use of an exposed token. When you can't answer "was it used?", that is the answer the public hears.

**Step 3: eradicate.** Remove the secret from current code. Rewrite history, meaning replace the old commits with new ones, only where warranted, with git-filter-repo 2.47 or later, then force-push, then a GitHub Support request. And note what the documentation says about Support: it assists only where rotation can't mitigate the risk.

The scope warning attached to this step: after a supply-chain compromise the scope is every credential reachable from the affected runtime.

**Step 4: recover.** Update dependent services with the new credential. If history was rewritten, have collaborators re-clone, and re-enable force-push protection. Close the alert as revoked, and document.

What goes wrong otherwise: partial rotation produced a second breach.

**Step 5: communicate.** Track internally. Tell collaborators exactly what to do with their clones. Keep a reachable disclosure contact, such as `SECURITY.md`.

What goes wrong otherwise: a researcher couldn't find a way to report a contractor's leak and went to the press. And concealment turned Uber's 2016 breach into a regulatory case.

**Step 6: prevent.** Push protection. Pre-commit and CI scanning. Secrets out of code. Short-lived credentials through OIDC. Least privilege. Staging named files and reviewing `git diff --cached`, instead of `git add .` with a dot. And scheduled rotation.

The evidence: hardcoded long-lived keys recur in every case of the next section.

**Why containment comes first.** This is the argument you must be able to make to someone who wants to start with the repository.

The repository isn't where the damage happens. The damage happens at the issuer, where the key is accepted. Until revocation the key works for whoever copied it. And revocation is the only step that is complete: it works against clones, forks, caches and screenshots alike.

GitHub's own guidance says the same: rotate immediately. Removing the secret from history is time-consuming and often unnecessary once the credential is revoked.

**What assessment has to produce.** Five facts, written down.

One: which secret, and what it can reach.

Two: the first commit that contains it, and when that commit was first pushed.

Three: which refs contain it.

Four: who could read it: repository visibility, forks, collaborators, CI logs.

Five: whether it was used, from the provider's logs.

And the sentence that divides the work: Git answers the second and the third. Only the issuer answers the last.

**When a history rewrite is warranted.** Rewrite when the data stays harmful after rotation, or can't be rotated. The textbook's list: personal data, customer records, proprietary model weights, a private key whose public half is pinned in devices, and a secret whose revocation takes weeks.

Quick quiz. An ordinary API key leaked. It was revoked within the hour. Do you rewrite history? A, yes, always, to be clean. B, not by reflex. Your answer?

**[PAUSE]**

B. Don't rewrite by reflex for an API key that was revoked within the hour. The rewrite costs every collaborator their clone, invalidates every recorded commit ID, strips signatures, and can't recall copies that already exist.

Either way: record the decision and its reason.

**The case studies.**

**[ON SCREEN]** The table of section 21B.15, row by row, with each source link visible.

The textbook says the root-cause column repeats one pattern: a long-lived, over-scoped credential written where it should never have been. Listen for it.

Uber, 2016. Exposed: a cloud access key in a private GitHub repository. Intruders downloaded tens of millions of records in a month. Root cause: a plaintext key in source code, reused passwords, and no multi-factor requirement on GitHub accounts. Lesson: a private repository is only as private as its weakest member account.

Toyota, 2022. Exposed: a data-server access key, public from December 2017 to September 2022, with 296,019 customers potentially exposed. Root cause: a subcontractor published internal code with a hardcoded key. Lesson: keys that never expire turn one mistake into a five-year exposure.

Samsung, 2022. Exposed: 6,695 secrets inside stolen source code. Root cause: thousands of credentials hardcoded in private code. Lesson: assume source code will leak.

Microsoft AI research, 2020 to 2023. Exposed: a storage URL in a public model repository that granted full control of an account holding 38 terabytes. Root cause: an over-scoped, long-lived sharing token committed to the repository. Lesson: a data-sharing URL is a credential. Share weights through read-only, expiring mechanisms.

Hugging Face tokens, 2023. Exposed: 1,681 valid tokens giving access to 723 organizations, 655 with write permission. Root cause: tokens committed to code. Lesson: a model-hub write token is a supply-chain credential.

Mercedes-Benz, 2024. Exposed: an employee token, public for about four months, that gave unrestricted access to the company's GitHub Enterprise Server. Root cause: a broad, long-lived token in a public repository. Lesson: one over-scoped token equals the whole code estate.

The New York Times, 2024. Exposed: a 273 gigabyte archive of repositories, leaked five months after a GitHub credential was exposed. Root cause: an exposed token with organization-wide read access. Lesson: least-privilege, expiring tokens bound the damage.

xAI, 2025. Exposed: an LLM API key with access to at least 60 private and fine-tuned models, valid two months after the first alert. Root cause: the key was hardcoded and pushed, and the alert was sent only to an individual. Lesson: an alert in one inbox isn't an incident process.

A contractor of CISA, 2025 to 2026. Exposed: administrative cloud credentials and plaintext passwords in a public repository for six months. Root cause: work material copied to a personal public repository with secret detection deliberately disabled. Lesson: controls an individual can switch off need organizational backstops and a leak playbook.

**The flags.** The report marks these details as partially confirmed, so you quote them as the cited articles do. The day-level timeline of the Mercedes-Benz case. The size of the New York Times archive, 273 gigabytes in the cited article and often rounded to 270. The Internet Archive user count. Samsung's own confirmation. And Toyota's original notice. And one negative finding: the report found no verified 2026 incident caused specifically by a key in a public Jupyter notebook. Notebooks are documented as a leak mechanism, not through a named breach.

**For an LLM engineer,** the textbook draws three conclusions. An LLM API key reaches more than a bill: the xAI key reached private and fine-tuned models. A link that shares weights or data is a credential, with a scope and a lifetime. And a model-hub token with write permission lets its holder replace what your users download.

## MENTAL MODEL

Section 21B.14 gives no analogy of its own, so here is one for this video. Imagine you lost the key to your house, with a tag on it that gives your address.

You can spend the morning looking for the key: the car, the office, the street. You may even find it. You still don't know who saw it or copied it while it was gone.

Or you can change the lock. That takes one call, and from that moment every copy of the old key, wherever it is, opens nothing.

Change the lock first. Then look for the key, to learn what was at risk and for how long.

Where the picture falls short: a house key opens one door. A credential may open many, and it may have opened them already without leaving a trace you can see from your side. That's why step two includes the provider's logs, and why the fifth fact can only come from the issuer.

And the picture explains the rewrite decision. Changing the lock does nothing for a diary that was lying in the open. Data that is harmful in itself, such as personal data or model weights, can't be revoked. For that, and for that only, the work on the repository is the main work.

## DIAGRAM

Try it now, thirty seconds, on paper. Draw a line with six stations and write the six steps on it, in order. Under station two, write the five facts. Then mark the facts that Git can answer. Say them out loud.

**[PAUSE]**

**[DIAGRAM]** A horizontal track with six stations. Draw the track, then mark the first station. Then hang the five assessment facts under station two, and mark which of them Git can answer.

```text
   1 CONTAIN  --->  2 ASSESS  --->  3 ERADICATE  --->  4 RECOVER  --->  5 COMMUNICATE  --->  6 PREVENT
   revoke or        five facts,     remove from        new credential   collaborators:        push protection,
   rotate at        written down    current code;      to dependent     what to do with       scanning, OIDC,
   the issuer                       rewrite history    services;        their clones;         least privilege,
      ^                 |           ONLY where         re-clone if      a reachable           named files and
      |                 |           warranted          rewritten        contact               git diff --cached
   the key stops        |
   working HERE         +-- a) which secret, and what it can reach
   (against every       +-- b) first commit, and when first pushed     <-- Git can answer
    clone, fork,        +-- c) which refs contain it                   <-- Git can answer
    cache, screenshot)  +-- d) who could read it (visibility, forks, collaborators, CI logs)
                        +-- e) was it used?                            <-- only the issuer's logs
```

Check your track. Contain, assess, eradicate, recover, communicate, prevent. The key stops working at station one, against every clone, fork, cache and screenshot. And Git answers two of the five facts: the first commit, and which refs contain it. One caution about the first: when that commit was first pushed is a question about the server.

**[DIAGRAM]** One caution about fact b. Git gives you the first commit and its dates. When that commit was first pushed is a question about the server; your clone can give you a hint, as you will see in the demonstration, and the platform's records give the rest.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/lab-31-1-tabletop`, and stop after the third snippet. The fixture is `ragdesk` again, with a bare server, two teammates' clones, and one new directory: `provider`. In it, a small script called `keyctl` stands in for the console of the service that issued the key. In a real incident that step happens in the provider's console, and the lab manual says it is the one that matters most.

Every secret here is a dummy.

**Step 0: confirm.**

```bash
git grep -n LLM_API_KEY -- .env
git log --oneline -S'DUMMY-KEY-not-a-real-secret-12345'
git status -sb
```

All three read. 🟢 SAFE.

<!-- snippet: ch21b/lab-31-1-tabletop/01-confirm -->
```text
$ ls
asha
home
kit
provider
ragdesk
ravi
server.git
$ cd ragdesk
$ git grep -n LLM_API_KEY -- .env
.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
$ git log --oneline -S'DUMMY-KEY-not-a-real-secret-12345'
0805fd8 Add staging settings
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

The report is true: the key is in `.env` on the current tip, it entered in commit `0805fd8`, and the branch is in sync with the server, so it has been pushed. That took three commands. Don't let confirmation turn into investigation. You know enough to act.

**Step 1: contain.**

```bash
../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
../provider/keyctl revoke DUMMY-KEY-not-a-real-secret-12345
../provider/keyctl issue
../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
```

Before the output: at this moment nothing in the repository has been touched. The file is still tracked. The commit is still on the server. Is the incident better or worse than it was a minute ago? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21b/lab-31-1-tabletop/02-contain -->
```text
$ ../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
ACTIVE   DUMMY-KEY-not-a-real-secret-12345
$ ../provider/keyctl revoke DUMMY-KEY-not-a-real-secret-12345
revoked  DUMMY-KEY-not-a-real-secret-12345
$ ../provider/keyctl issue
issued   DUMMY-KEY-rotated-not-a-real-secret-2
$ ../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345
REVOKED  DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

"ACTIVE", then "revoked", then a new key issued, then "REVOKED". The old key now opens nothing, for anyone, from any copy. The repository is exactly as it was, and the incident is fundamentally smaller. Everything after this line is assessment and cleanup, done without a clock running against you.

A real revocation isn't a Git command. It happens in the provider's console. It also changes what every service that uses the key can do, which is why step four exists: dependent services need the new credential.

**Step 2: assess.**

```bash
first=$(git log --format=%h --diff-filter=A -- .env); echo $first
git log -1 --format='%h%nauthor:    %an <%ae>%ncommitted: %cd%nsubject:   %s' --date=iso-local $first
git branch -a --contains $first
git tag --contains $first
git rev-list --count $first..origin/main
git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
git reflog show origin/main
```

All read. Seven commands. Match each to one of the five facts before you see the output. Which facts get no command at all? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21b/lab-31-1-tabletop/03-assess -->
```text
$ first=$(git log --format=%h --diff-filter=A -- .env); echo $first
0805fd8
$ git log -1 --format='%h%nauthor:    %an <%ae>%ncommitted: %cd%nsubject:   %s' --date=iso-local $first
0805fd8
author:    Lab User <you@example.com>
committed: 2026-09-07 10:10:00 +0530
subject:   Add staging settings
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
$ git rev-list --count $first..origin/main
3
$ git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
   5 DUMMY-KEY-not-a-real-secret-12345
$ git reflog show origin/main
d4b8762 refs/remotes/origin/main@{0}: update by push
```
<!-- /snippet -->

Read it as a report.

The first commit: `0805fd8`, by the lab user, committed on the seventh of September 2026 at ten past ten, "Add staging settings". That's the first half of fact b.

Which refs: `main`, the remote-tracking `main`, a remote-tracking feature branch, and the tag `v0.2.0`. That's fact c. A tag in the list means a release contains the secret.

Three commits lie between the first one and the server's tip. And over all commits, the key string occurs in five snapshots.

The last command is the hint for the second half of fact b. The reflog is Git's local record of the values a ref has had. The reflog of `origin/main` in your clone records when your clone saw the server's branch change, here "update by push". It's your clone's view, not the server's record. For the server's side you go to the platform.

Now the facts that got no command. Fact a: which secret and what it can reach. That's a question about the credential's type and scope, from the last video. Fact d: who could read it. That's repository visibility, forks, collaborators and CI logs: platform state. And fact e: was it used. Only the provider's logs. Git answered two of five.

**[ON SCREEN]** Stop the replay here.

The replay continues with eradication: removing the file at the tip, a rewrite, a mirrored force push, pruning. Those are 🔴 DANGEROUS operations, and each needs its five answers. They are the subject of the next two videos, together with the stale clone that pushes the secret back. For this incident, ask the question from the concept section first: the key is a revocable API key, and it has been revoked. Is a rewrite warranted? Write down your answer and your reason. Exercise 31.3 is about exactly that decision.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Starting with the repository.** Root cause: the damage happens at the issuer, where the key is accepted; until revocation the key works for whoever copied it.
2. **Rewriting history by reflex.** Root cause: for a revoked key the rewrite removes nothing that still matters, and it costs every collaborator their clone, invalidates recorded commit IDs and strips signatures.
3. **Rotating one credential after a runtime was compromised.** Root cause: the scope is every credential reachable from that runtime; partial rotation is how a second breach happens.
4. **Reporting "we found no use" from Git or from GitHub alone.** Root cause: whether the key was used is recorded at the issuer; Git answers only which commits and which refs.
5. **Sending the alert to one person.** Root cause: an alert in one inbox is not an incident process; the xAI key stayed valid two months after the first alert.

## PRODUCTION EXAMPLE

Now, out of the lab. Picture an AI company on a Tuesday. A scanner alert arrives for a provider key in a repository of evaluation scripts. The engineer on call follows the six steps, and writes one line per step in the incident channel.

At nine fourteen, contain: key revoked in the provider's console, new key issued, and the two services that use it are named.

At nine thirty-one, assess, five facts. The secret: a provider key with access to the company's fine-tuned models. First commit and first push: an ID, an author, a date, and pushed the same day according to the platform's activity record. Refs: `main` and one release tag. Who could read: the repository is internal, with forty collaborators, and one CI log printed the variable name but not the value. Was it used: the provider's log shows no calls from unknown addresses in the window.

At nine forty, eradicate: the file is removed from the tip and ignored. Rewrite decision: not warranted. The key is revoked and the provider's logs show no use. Reason recorded.

At five past ten, recover: both services run with the new key, and the alert is closed as revoked.

At ten past ten, communicate: a short note to the team with what happened and that no action on clones is needed, because nothing was rewritten.

Afternoon, prevent: push protection is enabled for the repository, and the team's guide gains one sentence about staging named files and reading `git diff --cached` before every commit.

Under an hour from the alert to recovery, and the first step did most of the work.

## PRACTICE EXERCISE

Your turn. Do Exercise 31.2, "Fix the order", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Before you rearrange anything, predict for each step in the exercise's sequence what is still possible for an attacker while the team is busy with that step. The step after which the answer becomes "nothing" is the one that must come first.

The challenge is Exercise 31.3, "Rewrite or not?", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q324: "How do you investigate a leaked secret?"

Read the question on screen. Say your answer out loud.

**[PAUSE]**

Notice the word "investigate", and don't let it pull you into the repository first. A strong answer says what happens before the investigation and why, then gives the investigation as the five facts, each with the place the answer comes from: the credential's definition, Git, the platform, the issuer. It names the commands for the two facts Git answers. It ends with the decision the investigation feeds, and with what is recorded. The follow-up is the board asking, months later, whether anyone cloned the repository with a leaked GitHub token: recall from video 164 what a search by token hash returns, how long Git events are retained, and what had to be set up before the incident.

## RECAP

Let's land this.

You should now be able to say:

- The six steps are contain, assess, eradicate, recover, communicate, prevent, and the order matters more than the tools.
- Revocation comes first because the damage happens at the issuer, and it is the only step that works against every copy; it may be all that is needed.
- An assessment produces five facts: the secret and its reach, the first commit and first push, the refs, who could read it, and whether it was used; Git answers the second and third, and only the issuer answers the last.
- Rewrite history when the data stays harmful after rotation or cannot be rotated, not by reflex for a revoked key; record the decision.
- The cases repeat one root cause: a long-lived, over-scoped credential written where it should never have been.

## HOMEWORK

Read sections 21B.14 and 21B.15 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md). Read [`cheatsheets/security-cheat-sheet.md`](../../cheatsheets/security-cheat-sheet.md).

Today you put a leak response in order, and saw an incident shrink before anyone touched the repository. Say the six steps aloud, in order, before the next video. Next time: history rewriting as an operation, and its mechanics seen locally. Until then, look at the state first and type second. See you in the next one.

# V165: Secret scanning and push protection and what they do not cover, Dependabot, code scanning, and a way to report vulnerabilities

- **Part.** 7: Security
- **Module.** 30
- **Planned minutes.** 24
- **Prerequisites.** V089, V164
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.12 and 21B.13
- **Demo scripts.** `labs/ch21b/push-guard.sh`, `labs/ch21b/lab-30-1-push-check.sh`, `labs/ch21b/lab-30-2-dependabot.sh`; a screen walkthrough of Lab 30.1 in [`lab-manual/m30-repository-security.md`](../../lab-manual/m30-repository-security.md). Every secret is a dummy string that no scanner pattern matches.

## HOOK

**[ON SCREEN]** A terminal. A push is rejected: the remote says a commit contains a secret.

A developer's push is blocked. Good: the protection worked. The developer does the natural thing. They delete the file, commit the deletion, and push again.

Blocked again, with the same message, naming the same commit.

Now they are confused and a little annoyed, because the file is gone. Some developers at this point reach for the bypass, choose a reason from a list, and the secret goes to the server after all.

You know from the last video why the second push was blocked: a deletion adds a commit and removes nothing, and the push would still deliver the first commit. What this developer did not know is that they were standing at the one moment where a full repair is cheap. In this video you make that repair, and you learn what the block covers and what it does not.

## INTRODUCTION

The last video ended on a hard fact: after the first push, you cannot un-publish. So the valuable controls are the ones that act before the first push. This video is about those, and about the rest of a repository's baseline.

Two sections. Section 21B.12: secret scanning and push protection on GitHub, what they cover, what they do not, and a local analogue of a push-time check in plain Git. Section 21B.13: Dependabot, code scanning, and a way for outsiders to report vulnerabilities to you.

**[ON SCREEN]** Lower third: GitHub, then Git.

Keep the layers apart with care in this video. Everything about secret scanning and push protection is platform behavior, described from the documentation; nothing was run against GitHub. The demonstration is a `pre-receive` hook on a bare repository that you control. It reproduces the behavior of a push-time check so that you can see it. It is not how GitHub implements push protection.

## LEARNING OBJECTIVES

After this video you can:

- say what secret scanning and push protection do and name kinds of leak they do not stop;
- model a push-time check locally and show why deleting the file does not unblock the push;
- remove a secret from unpushed commits so that the push is accepted;
- write a Dependabot configuration for a Python project, Docker and Actions;
- say what code scanning and private vulnerability reporting add.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**Secret scanning** scans the entire Git history on all branches, plus issues, pull requests, discussions and wikis. It runs for free on public repositories. Organization-owned private and internal repositories need GitHub Secret Protection, which costs 19 dollars per active committer per month and is sold on Team and Enterprise plans.

**Push protection** blocks a push that contains a recognized secret before it reaches the repository. It comes in two forms.

**[ON SCREEN]** The two-column table of section 21B.12.

Push protection for users: on by default since 29 February 2024. It requires nothing, on GitHub.com only. It protects your pushes to public repositories. And a bypass leaves no alert, unless repository protection is also on.

Push protection for repositories: off by default. It requires GitHub Secret Protection, which is free on public repositories. It protects every push to that repository, by anyone. And a bypass leaves an alert.

It covers command-line pushes, commits made in the web interface, file uploads, REST API requests, and, on public repositories, interactions through the GitHub MCP server.

By default anyone with write access can bypass a block by choosing a reason. "It's used in tests" and "It's a false positive" create a closed alert; "I'll fix it later" creates an open one. The bypass is written to the audit log and emailed to administrators. Delegated bypass, part of Secret Protection for organization-owned repositories, restricts who may bypass and puts other contributors' requests through a review that expires after seven days.

**What it does not cover.** The textbook says GitHub's default protection is narrower than most engineers assume. Four points.

User push protection guards only pushes to public repositories. A private repository without Secret Protection has no push-time check at all.

It blocks high-confidence provider patterns. Generic secrets such as passwords and connection strings are not blocked, and AI-detected passwords are explicitly excluded from push protection.

A block is a prompt, not a wall, unless delegated bypass is configured.

And coverage differs by provider, in three independent columns: whether the provider is notified for public leaks, whether push protection blocks the pattern, and whether there is a validity check.

**[ON SCREEN]** The provider table of section 21B.12, as read for the Phase 0 report on 1 October 2026.

For an AI/ML engineer this table is worth a minute. Keys of OpenAI, Anthropic, Hugging Face user access tokens, and several other model providers: yes in all three columns. A Google API key: provider notified, validity checked, and not blocked by push protection. A Google Gemini API key: not notified, not blocked, a user alert only. Mistral, Cohere, DeepSeek, Pinecone: not notified, but blocked and checked. Perplexity, LangSmith, Weights and Biases keys: not notified, blocked, no validity check. PyPI tokens, npm tokens and GitHub personal access tokens: notified and blocked.

The list changes. Re-read it for the providers you use.

And partner notification does not guarantee revocation. GitHub revokes its own leaked tokens. Anthropic documents automatic deactivation of keys found in public GitHub repositories. Hugging Face lets anyone invalidate a leaked token through a revocation endpoint. But an xAI key flagged on 2 March 2025 stayed valid until 30 April 2025.

**[ON SCREEN]** Callout: Unverified. Whether OpenAI disables API keys it finds on the public internet could not be confirmed from a primary page for the Phase 0 report. How Hugging Face and OpenAI handle partner notifications from GitHub is not documented in the pages read.

**Scanners.** As of 1 October 2026 the textbook lists TruffleHog, which verifies candidates against provider APIs and can enumerate deleted and hidden commits; gitleaks, which declares itself feature-complete with security patches only; Betterleaks, to which gitleaks' author moved, and whose governance and detection-quality claims come from one news article and are not independently verified; detect-secrets, whose last release is from May 2024; and git-secrets, which has no tagged releases. None is installed for the course, so none is demonstrated. The advice: run your choice in two places. As a pre-commit hook for fast feedback, and in CI over the full history, where it cannot be skipped.

**Dependabot** is three features that share a name.

Alerts tell you that a dependency on the default branch has a known vulnerability. They need the dependency graph. Only advisories reviewed by GitHub raise alerts; archived repositories are not scanned; and for Actions, alerts exist only for actions referenced by semantic version, not by commit ID.

Security updates open a pull request that raises a vulnerable dependency to the minimum patched version. They need alerts.

Version updates open pull requests to keep dependencies current, vulnerable or not. They are enabled by committing a file, `.github/dependabot.yml`. Since 14 July 2026 a default cooldown of 3 days applies to version updates and not to security updates.

All three are free on every plan. And note the trade-off with the advice of V159: pinned actions get no Dependabot alerts, so version updates must move the pins.

Two things older configurations get wrong. The `reviewers` option was removed on 8 August 2025 in favor of CODEOWNERS. And the comment commands, such as asking Dependabot to merge in a comment, stopped working on 27 January 2026. Without explicit configuration at most five version-update pull requests stay open at once; security updates do not count toward that limit.

**Code scanning** analyzes code for vulnerabilities and coding errors with CodeQL, or with third-party tools that upload results. It runs on GitHub Actions and consumes minutes. It is free on public repositories and needs GitHub Code Security, at 30 dollars per active committer per month, on private ones. GitHub recommends default setup. One documented surprise: if a repository with default setup sees no pushes and no pull requests for six months, the weekly scheduled scan is disabled. And a boundary: code scanning does not find secrets or vulnerable dependencies. Those are the features above.

**A security policy and private vulnerability reporting.** A `SECURITY.md` file states which versions you support and how to report a problem; an organization can provide a default through its `.github` repository. Private vulnerability reporting is a separate feature that administrators of public repositories can enable. It adds a "Report a vulnerability" button on the Advisories page, and the report lands in a private draft advisory. The reason to do both is a case you will hear in the next video: a researcher who found a contractor's leaked credentials could not find a way to report them and went to the press.

## MENTAL MODEL

Think of the commits you have not pushed as editions that have not left the building.

From the last video: publishing a correction does not recall yesterday's edition, and withdrawing it from your own archive does not either. The textbook said that analogy breaks for unpushed commits: an edition that never left the building can be pulped.

A push-time check is the person at the loading dock who looks into every box before it leaves. If one box contains the wrong edition, the whole shipment is refused. Putting a correction slip on top of the shipment does not help: the box is still in it. You have to take the box out. And because the shipment is still in the building, you can.

The textbook's sentence: before the first push is the one moment at which rewriting history fully removes a secret. A push-time block exists to keep you there.

Then two things the picture needs. The checker has a list of what the wrong editions look like. Anything not on the list goes through. And there are two checkers who look alike: the one at your own desk, the client-side hook, whom you can walk past with one option; and the one at the dock, on the server, whom you cannot. Local hooks are advice. A server-side check is enforcement.

## DIAGRAM

**[DIAGRAM]** Three rows. In each, the server's tip on the left and the commits to be pushed on the right. Draw the first row and its rejection. Then the second, and ask whether the new commit changes what the push would deliver. Then the third.

```text
   server: origin/main at X          what the push would deliver             result

   1)  X  <---  A (adds .env   <---  B (other work)                          DECLINED:
                 with the key)                                               the push contains A

   2)  X  <---  A (adds .env)  <---  B  <---  C (deletes .env)               DECLINED again:
                                                                             A is still delivered;
                                                                             C changes only the
                                                                             newest snapshot

   3)  X  <---  A' (same change      <---  B' (other work)                   ACCEPTED:
                 without .env;                                               no commit that would
                 .gitignore added)                                           be delivered contains
                                                                             the key
        A and B were never pushed, so replacing them with A' and B' costs nobody anything
```

**[DIAGRAM]** Row 2 is what people try. Row 3 is the repair. The check does not look at the tip. It looks at every commit the push would introduce.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/push-guard`. Git, in the sandbox: a bare `server.git`, a clone called `triage`, and a kit with two small hooks.

**Step 1: the server-side guard.**

```bash
cat kit/pre-receive
cp kit/pre-receive server.git/hooks/pre-receive
```

<!-- snippet: ch21b/push-guard/01-install-server-hook -->
```text
$ cat kit/pre-receive
#!/bin/sh
# Server-side guard: refuse a push if any commit it introduces contains a secret pattern.
pattern='DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
while read old new ref; do
  case "$new" in *[!0]*) ;; *) continue ;; esac          # a deletion: nothing to scan
  for c in $(git rev-list "$new" --not --all); do
    if git grep -q -E "$pattern" "$c"; then
      echo "push declined: $ref: commit $(git rev-parse --short "$c") contains a secret pattern"
      exit 1
    fi
  done
done
$ cp kit/pre-receive server.git/hooks/pre-receive
```
<!-- /snippet -->

Read the hook. A `pre-receive` hook runs on the receiving side before any ref is updated, and rejects the whole push by exiting non-zero. For every ref in the push it lists the commits the push would introduce, with `git rev-list` of the new tip, excluding everything the server already has. For each of those commits it runs `git grep` for a pattern. One match, and it prints the commit and exits with 1.

**Step 2: a push with a secret.**

```bash
printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env
git add -A && git commit -q -m 'Add local settings'
git push
```

`git commit` is 🟢 SAFE; `git push` is 🟡 CAUTION.

<!-- snippet: ch21b/push-guard/02-push-blocked -->
```text
$ cd triage
$ printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env
$ git add -A && git commit -q -m 'Add local settings'
$ git push 2>&1
remote: push declined: refs/heads/main: commit 49384d9 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

"Push declined", naming commit `49384d9`, and "remote rejected, pre-receive hook declined". Nothing reached the server.

**Step 3: the natural reaction.**

```bash
git rm -q .env && git commit -q -m 'Remove .env'
git log --oneline origin/main..main
git push
```

`git rm` is 🟡: it deletes the file on disk and removes its index entry. **[PAUSE]** Two unpushed commits now: one adds the file, one removes it. The tip is clean. Is the push accepted?

<!-- snippet: ch21b/push-guard/03-deleting-does-not-unblock -->
```text
$ git rm -q .env && git commit -q -m 'Remove .env'
$ git log --oneline origin/main..main
8546eb9 Remove .env
49384d9 Add local settings
$ git push 2>&1
remote: push declined: refs/heads/main: commit 49384d9 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

Declined again, and it names the same commit, `49384d9`. The push would deliver that commit, whose snapshot contains the key, whatever a later commit does. The textbook adds: GitHub's push protection behaves the same way and for the same reason. The secret has to be removed from the commit that introduced it.

**Step 4: replace the unpushed commits.**

```bash
git reset -q --soft origin/main
git status -s
printf '.env\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore .env'
git push
```

`git reset --soft` to the upstream tip is 🟡 CAUTION: it moves the branch to the upstream tip; the index and working tree keep your changes. The preview is `git log` for the unpushed range, which you saw. The recovery is `git reset --soft ORIG_HEAD`.

Here the index after the reset holds the net effect of the two commits, which is nothing: the file was added and removed. So the status is empty, and the only new commit is the ignore rule.

<!-- snippet: ch21b/push-guard/04-rewrite-unpushed-commits -->
```text
# Nothing was pushed, so the two commits can be replaced. This is the cheap moment.
$ git reset -q --soft origin/main
$ git status -s
$ printf '.env\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore .env'
$ git push 2>&1
To ../server.git
   c3cf659..5584d4f  main -> main
[exit status: 0]
$ git -C ../server.git log --oneline main
5584d4f Ignore .env
c3cf659 Add ticket router
```
<!-- /snippet -->

Accepted. The server's `main` has two commits: the original one and "Ignore .env". Commit `49384d9` exists only in your local object database and reflog. It never left the building.

**Step 5: the client-side hook.**

<!-- snippet: ch21b/push-guard/05-client-hook -->
```text
$ cat ../kit/pre-commit
#!/bin/sh
# Client-side guard: refuse a commit whose staged additions match a secret pattern.
if git diff --cached -U0 | grep -E '^\+.*DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' > /dev/null; then
  echo "pre-commit: a staged line matches a secret pattern; commit refused" >&2
  exit 1
fi
$ cp ../kit/pre-commit .git/hooks/pre-commit
$ printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml
$ git add debug.yaml
$ git commit -m 'Add debug settings'
pre-commit: a staged line matches a secret pattern; commit refused
[exit status: 1]
```
<!-- /snippet -->

A `pre-commit` hook that looks at the staged additions with `git diff --cached` and refuses a commit whose added lines match the pattern. It catches the mistake one step earlier: the commit is refused, exit status 1.

```bash
git commit -q --no-verify -m 'Add debug settings'
git push
```

`git commit --no-verify` is 🟡 CAUTION: as `git commit`, without two hooks. **[PAUSE]** The developer skips the hook. What stops the secret now?

<!-- snippet: ch21b/push-guard/06-client-hook-bypassed -->
```text
$ git commit -q --no-verify -m 'Add debug settings'
[exit status: 0]
$ git log --oneline -1
4be6dc6 Add debug settings
# The client hook is advice. The server hook is enforcement:
$ git push 2>&1
remote: push declined: refs/heads/main: commit 4be6dc6 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
```
<!-- /snippet -->

The commit succeeds, `4be6dc6`. And the push is declined by the server. The comment in the transcript is the rule: the client hook is advice; the server hook is enforcement. On GitHub the corresponding enforcement points are push protection, push rulesets and required checks.

**Step 6: when the secret is in an earlier unpushed commit.** Replay `labs/run ch21b/lab-30-1-push-check`. Here there are two unpushed commits, and the secret is in the first; the second is real work that must be kept. A soft reset would mix them. The tool is an interactive rebase.

<!-- snippet: ch21b/lab-30-1-push-check/03-fix-earlier-commit -->
```text
# The secret is in an earlier unpushed commit. Edit that commit; keep the later one.
$ git rebase -i origin/main
--- todo list as Git opened it (comment lines removed) ---
pick 49384d9 # Add local settings
pick 3f376a8 # Add ticket priority
--- todo list as saved ---
edit 49384d9 # Add local settings
pick 3f376a8 # Add ticket priority
Rebasing (1/2)
Stopped at 49384d9...  # Add local settings
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
$ git rm -q --cached .env
$ printf '.env\n' > .gitignore && git add .gitignore
$ git commit -q --amend --no-edit
$ git rebase --continue 2>&1
Rebasing (2/2)
Successfully rebased and updated refs/heads/main.
```
<!-- /snippet -->

`git rebase -i` is 🟡: it replaces commits with new ones, and the reflog keeps the old. The todo list is changed in one word: `pick` becomes `edit` for the commit with the secret. Git stops there. The file is taken out of the index with `git rm --cached`, which is 🟡 CAUTION, an ignore rule is added, and the commit is amended; `git commit --amend` is 🟡 CAUTION. Then the rebase continues and replays the second commit.

<!-- snippet: ch21b/lab-30-1-push-check/04-push-accepted -->
```text
$ git log --oneline origin/main..main
dc90cbc Add ticket priority
1668a86 Add local settings
$ git grep -c DUMMY-KEY $(git rev-list origin/main..main) || echo "no commit to be pushed contains the key"
no commit to be pushed contains the key
$ git push 2>&1
To ../server.git
   c3cf659..dc90cbc  main -> main
[exit status: 0]
```
<!-- /snippet -->

Two commits again, with new IDs, `1668a86` and `dc90cbc`. Before pushing, the transcript checks the same thing the server will check: does any commit to be pushed contain the key? None does. The push is accepted.

**Step 7: what the check cannot see.**

**[PAUSE]** A file with a database password, an ordinary phrase, in a YAML file. The pattern list knows the dummy keys. Is the push accepted?

<!-- snippet: ch21b/lab-30-1-push-check/05-not-covered -->
```text
# What the check cannot see: a secret whose shape is not in its pattern list.
$ printf 'db_password: correct-horse-battery-staple\n' > database.yaml
$ git add database.yaml && git commit -q -m 'Add database settings'
$ git push 2>&1
To ../server.git
   dc90cbc..ffe1804  main -> main
[exit status: 0]
```
<!-- /snippet -->

Accepted, exit status 0. A secret whose shape is not in the pattern list goes straight through. That is the second point of "what it does not cover", made visible.

**Step 8: a Dependabot configuration.** Replay `labs/run ch21b/lab-30-2-dependabot`.

<!-- snippet: ch21b/lab-30-2-dependabot/01-file -->
```text
$ cat .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "uv"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      python-minor-and-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 7
```
<!-- /snippet -->

Three entries. The `uv` ecosystem for the Python project, weekly, with a group that collects minor and patch updates into one pull request. `docker`, weekly. And `github-actions`, weekly, with a cooldown of seven days, which is longer than the default of three. The file was assembled from the keys in the options reference, parse-checked locally, and not run on GitHub.

<!-- snippet: ch21b/lab-30-2-dependabot/02-parse -->
```text
$ cat check.py
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
assert doc["version"] == 2, "version must be 2"
for u in doc["updates"]:
    missing = [k for k in ("package-ecosystem", "schedule") if k not in u]
    if "directory" not in u and "directories" not in u:
        missing.append("directory or directories")
    print(f'{u["package-ecosystem"]:<15} {u.get("directory", u.get("directories"))!s:<4} {u.get("schedule", {}).get("interval", "-"):<7} missing={missing}')
$ python3 check.py .github/dependabot.yml
uv              /    weekly  missing=[]
docker          /    weekly  missing=[]
github-actions  /    weekly  missing=[]
[exit status: 0]
```
<!-- /snippet -->

A small check script: the version must be 2, and each entry needs an ecosystem, a directory and a schedule. Three lines, nothing missing. It proves that the file is well formed, and nothing about what GitHub will do with it.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

Part B of Lab 30.1, on your practice repository, in your normal shell. The interface changes; the lab text and the linked documentation are the reference, and no GitHub output was captured by the authors. Use only the dummy value the lab prescribes. Never a real credential, not even a revoked one.

```bash
gh repo edit YOUR-ORG/practice-repo --enable-secret-scanning --enable-secret-scanning-push-protection
gh api repos/YOUR-ORG/practice-repo --jq '.security_and_analysis'
```

`gh repo edit` is 🟡 CAUTION: it changes settings; the preview is `gh repo view` with JSON fields, and the recovery is to set the previous value. The second command reads the setting back; the lab notes that it needs admin permission on the repository.

Then the lab has you push the dummy file on a branch. Before you push, predict: will this push be blocked? Think about what the chapter said about the dummy values: they are spelled so that no scanner pattern matches. Then watch what happens, and find in the repository's security settings where the two features show their state. Delete the branch afterwards, as the lab says.

## COMMON MISTAKES

1. **Deleting the file in a new commit after a block.** Root cause: the push would still deliver the commit that introduced the secret; the secret has to be removed from that commit.
2. **Bypassing the block with "I'll fix it later".** Root cause: after the push the secret is in every repository that fetches it, and the cheap moment is over.
3. **Assuming push protection covers a private repository.** Root cause: user push protection guards only pushes to public repositories; a private repository without Secret Protection has no push-time check at all.
4. **Assuming every kind of secret is blocked.** Root cause: push protection blocks high-confidence provider patterns; generic passwords and connection strings are not blocked, and coverage differs by provider.
5. **Treating a `pre-commit` hook as the control.** Root cause: it is skipped with `--no-verify` and is not cloned; only a server-side check is enforcement.

## PRODUCTION EXAMPLE

An AI team starts a new private repository for a retrieval service. On day one the tech lead writes down the baseline, and for each layer what it misses.

Push protection for the repository, with Secret Protection, because user push protection would not cover a private repository at all. What it misses: generic passwords, and providers outside the pattern list; the team checks the supported-pattern table for the three providers it uses and finds that one of them is not blocked.

A scanner as a pre-commit hook and again in CI over the full history. What it misses at the desk: anyone who passes `--no-verify`. That is why it also runs in CI.

A Dependabot file with three ecosystems, and CODEOWNERS for review, since the old `reviewers` option is gone. What it misses: alerts for actions pinned by commit ID, which is why the Actions entry is there to move the pins.

Code scanning with default setup. What it misses: secrets and vulnerable dependencies, which are the other layers' job.

And a `SECURITY.md` with a contact. What it misses: nothing technical. It exists so that the person who finds the team's mistake can tell the team first.

## PRACTICE EXERCISE

Do Lab 30.1, "Push protection, and what a push-time check catches", in [`lab-manual/m30-repository-security.md`](../../lab-manual/m30-repository-security.md). Part A runs in `labs/shell`; Part B in your normal shell.

In Part A, before each push, predict whether the server will accept it and, if not, which commit it will name. Before the repair, decide which tool fits: a soft reset or an interactive rebase, and why. In Part B, predict whether the dummy value will be blocked.

The challenge is Exercise 30.6, "A baseline for a new ML repository", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q316: "Push protection is enabled for all your users. Name three kinds of leak it will not stop."

A strong answer starts by saying exactly what "for users" means: whose pushes, to which repositories. Then it gives three leaks that are different in kind, each tied to a documented limit: one about where the push goes, one about what the secret looks like, one about what a person can do at the prompt. It may add a fourth about secrets that never pass through a push at all. The follow-up is the hook of this video: a developer hits a block, deletes the file in a new commit and pushes again. Say what happens, why, and what the correct recovery is, with the two tools and when each fits.

## RECAP

You should now be able to say:

- Secret scanning reads the whole history and more; push protection blocks recognized patterns at push time, by default only for a user's pushes to public repositories.
- It does not block generic secrets, coverage differs by provider, and a block is a prompt unless delegated bypass is configured.
- A deletion commit does not unblock a push, because the push still delivers the commit with the secret; replace the unpushed commits with a soft reset or an interactive rebase.
- A client-side hook is advice; a server-side check is enforcement.
- Dependabot is alerts, security updates and version updates; code scanning finds neither secrets nor vulnerable dependencies; a security policy gives reporters a way to reach you.

## HOMEWORK

Read sections 21B.12 and 21B.13 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md). Do Lab 30.2, "A Dependabot configuration", in [`lab-manual/m30-repository-security.md`](../../lab-manual/m30-repository-security.md); then Exercise 30.3, "Blocked or not?", and Exercise 30.4, "The baseline of a public repository", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

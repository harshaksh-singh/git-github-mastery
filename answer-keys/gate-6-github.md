# Answer key, Gate 6: GitHub

> **For the examiner.** This file holds the model answers, the marking guidance and the real outputs for [Gate 6](../assessments/gate-6-github.md). A learner who has failed the gate does not get this file: they get the remediation map in the gate file and variant B. The transcripts are real output of `labs/gates/g6-predict.sh` and `labs/gates/g6-evidence.sh` on Git 2.55.0 and OpenSSH. Nothing was run against GitHub. Every statement about GitHub's behavior is taken from the textbook section named in the reference line, which cites GitHub's documentation.

**Marking, in general.** Mechanism and layer. A statement that puts a GitHub rule into Git ("Git refuses the push because the branch is protected" is acceptable; "Git checks the reviews" is not) loses its point. In the cases, a wrong blocker costs a point, as the gate file says.

---

## Part 1: Concepts

### C1 (5 points)

**Model answer.** Git data that the mirror contains: the annotated tag (a tag object and a ref); the commits of the merged pull request (they are reachable from the base branch, or, after a squash or rebase merge, their replacements are); `.github/CODEOWNERS`, which is a tracked file that GitHub interprets. Git data that GitHub wrote and the mirror contains: `refs/pull/88/head`, a read-only ref in the base repository that GitHub creates when the pull request opens (and `refs/pull/88/merge` while a test merge exists). GitHub objects that no Git command copies: the release (title, notes, attached files; it points at a tag name), the review comments and approvals, the ruleset, the issue. They live in GitHub's database and are reached through the API, for example with `gh api`. "Merged", in Git terms: GitHub marks a pull request as merged when its head commits have become reachable from its base branch, by whatever route; for a squash or rebase merge through the button GitHub records the merge itself, because the head commits never become reachable. The pull request as an object, its number, its discussion and its "merged" flag are GitHub data.

**Marking.** 1 point: the three Git items. 1 point: `refs/pull/88/head` as Git data written by GitHub. 1 point: the four GitHub objects. 1 point: what a release is relative to a tag. 1 point: "merged" as reachability of the head commits from the base.

**Common wrong answers.** "A release is a tag." "Pull requests are branches." "A mirror clone contains everything."

**Reference.** Chapter 15, sections 15.2 and 15.12; Chapter 17, sections 17.2 and 17.13.

### C2 (5 points)

**Model answer.** Authentication establishes which account a connection belongs to; authorization decides what that account may do to this repository. "Repository not found" comes after authentication succeeded, or with no credential at all: the server attached the request to an account or token, found that it cannot see the repository, and answered as if the repository did not exist. GitHub does that on purpose, "to avoid confirming the existence of private repositories": a "forbidden" would tell a stranger that the name is taken. Root causes, all of them about identity: the wrong account's credential answered (two accounts on one machine); a fine-grained token that does not include this repository; a credential that is not authorized for the organization's single sign-on; access that was never granted or was removed; and, the only non-identity cause, a misspelled, renamed or transferred repository. Who the server thinks you are: over HTTPS, `gh auth status` (and which helper answers: `git config get --all --show-origin credential.helper`); over SSH, `ssh -T git@github.com`, whose documented answer greets the account by name.

**Marking.** 1 point: the two terms. 1 point: the server authenticated and then hid the repository. 1 point: why 404. 1 point: four causes. 1 point: both commands.

**Common wrong answers.** "The URL is wrong" as the only idea. "The token expired" (that produces an authentication failure, not this message). "GitHub is down."

**Reference.** Chapter 16, sections 16.2, 16.17 and 16.19 (root-cause box).

### C3 (5 points)

**Model answer.** "Commits" is `git log base..head`: the commits reachable from the head and not from the base. "Files changed" is `git diff base...head`: the diff from the merge base of base and head to the head. A squash merge writes one commit with one parent on `main`. The content of the first branch arrived; none of its commits became an ancestor of `main`. The second branch was built on top of those commits, so they are reachable from its head and not from `main`: `base..head` lists them, and the merge base is still the original fork point, so the diff shows their changes again and may conflict. Repair: replay only the new commit onto `main`, `git rebase --onto main <old branch tip> <second branch>`, and update the pull request with `git push --force-with-lease`. GitHub does not notice because the merge base comes from parent links only; Git never compares patches to guess that a commit "is already there", and GitHub shows what Git computes.

**Marking.** 1 point per tab (2). 1 point: content without ancestry, the merge base did not move. 1 point: `rebase --onto` with the right three arguments. 1 point: why nothing detects it.

**Common wrong answers.** "GitHub's cache is stale." "The base branch is wrong" (true in other cases, not here). "Merge `main` into the branch": the list of commits stays.

**Reference.** Chapter 17, sections 17.3 and 17.12 (root-cause box); Chapter 9, section 9.5.

### C4 (5 points)

**Model answer.**

| | Merge commit | Squash | Rebase |
|---|---|---|---|
| On `main` afterwards | your commits and one merge commit (`--no-ff`) | one new commit | one new commit per original commit, no merge commit |
| Reviewed commit IDs | preserved | not present | not present; new IDs always |
| Committer | yours on your commits; GitHub on the merge commit | GitHub | updated by GitHub |
| Signature | your commits keep theirs; the merge commit is signed by GitHub | signed by GitHub | no commit signature verification |
| Bisect | per commit, or per pull request with `--first-parent` | per pull request | per commit |
| Revert of the whole change | one command, `git revert -m 1 <merge>`, with the re-merge trap | one command | one revert per commit |

**Marking.** 1 point for each of the first four rows that is right in all three columns, 1 point for the last two rows together.

**Common wrong answers.** "Rebase keeps my commits." "Squash keeps the signatures." "All three are the same for bisect."

**Reference.** Chapter 17, sections 17.8 and 17.9; Chapter 18, section 18.10.

### C5 (5 points)

**Model answer.** Rulesets have no priority. Every active ruleset that targets the ref, from the organization and from the repository, and the classic rule that matches it are added together; where the same rule is set differently, the most restrictive version applies. Exemptions: a ruleset binds everyone, administrators and organization owners included, except the actors on its bypass list (modes: always, for pull requests only, exempt). A classic rule does not bind people with admin permission unless "Do not allow bypassing the above settings" is selected. A required status check is a name in a list: the merge is allowed when the newest commit has a passing result under each name, from whoever reported it. Consequences: (1) a workflow that is skipped by a path filter, a branch filter or `[skip ci]` reports nothing, and the check stays "Expected" forever; (2) a job that is skipped inside a workflow that ran reports success, so a required check can be green without having run; (3) checks count only for certain events, so a manual `workflow_dispatch` run satisfies nothing, and a merge queue needs the `merge_group` trigger; (4) anyone with write access can report a status under that name through the API unless the check is pinned to its expected GitHub App.

**Marking.** 1 point: aggregation, strictest wins, classic included. 1 point: who is bound in rulesets and in classic rules. 1 point: "a name". 2 points: three correct consequences (two consequences 1).

**Common wrong answers.** "The repository ruleset overrides the organization's." "Admins can always merge." "A required check is the workflow file."

**Reference.** Chapter 18, sections 18.4, 18.5, 18.8 and 18.14.

### C6 (5 points)

**Model answer.** First surprise: the file by itself only requests reviews. It becomes a gate when a rule on the base branch requires review from code owners; then one owner of every changed path must approve. Second surprise: `docs/*` matches files directly in `docs/` and, as GitHub documents, "not further nested files", so `docs/guides/x.md` falls to an earlier, more general line; `/docs/` covers the directory and everything below it. Location: GitHub looks in `.github/`, then the repository root, then `docs/`, and uses the first file it finds; for a pull request it reads the file from the base branch, so a pull request that edits the file is judged by the old version. Matching: for each changed path the last line whose pattern matches decides, so general lines go first and specific ones last. Differences from `.gitignore`: `!` negation does not work, `[ ]` character ranges do not work, `\#` escaping does not work; and CODEOWNERS labels files one path at a time, while gitignore prunes directories, so `git check-ignore` is not a tester for it. Validity: an owner must be a user or team with explicit write access to the repository, and a team must be visible; an invalid line assigns nobody.

**Marking.** 1 point: request against requirement. 1 point: `docs/*`. 1 point: location order and base branch. 1 point: last match wins and two differences. 1 point: write access.

**Common wrong answers.** "First match wins." "CODEOWNERS uses gitignore rules." "The file on my branch counts."

**Reference.** Chapter 19, sections 19.3 to 19.7 and 19.12.

---

## Part 2: Prediction

### P1 (5 points)

<!-- snippet: gates/g6-predict/p1-answer -->
```text
$ git log --oneline main | wc -l | tr -d " "
2
$ git show -s --format=%p main | wc -w | tr -d " "
1
$ git diff --stat main feature/proration
$ git branch --merged main
* main
$ git log --oneline main..feature/proration | wc -l | tr -d " "
3
$ git branch -d feature/proration
error: the branch 'feature/proration' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/proration'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
[exit status: 1]
$ git cherry main feature/proration | cut -c1
+
+
+
```
<!-- /snippet -->

Two commits on `main`; the squash commit has one parent. The trees are equal (empty diff): the content was merged. The ancestry was not: the branch is not listed as merged, its three commits are not reachable from `main`, `-d` refuses, and `git cherry` marks all three with `+` because no single commit on `main` has the same patch as any of them.

**Marking.** 1 point: 2 and 1. 1 point: empty diff. 1 point: only `main` is listed; 3. 2 points: `-d` refuses, and `+`, `+`, `+`. The expected wrong answer for `git cherry` is three `-` ("the changes are in main").

**Reference.** Chapter 17, section 17.9 (root-cause box "After a squash merge ..."); Chapter 8, section 8.12.

### P2 (5 points)

<!-- snippet: gates/g6-predict/p2-answer-a -->
```text
# What a pull request from feature/escalation into main would show:
$ git log --format=%s main..feature/escalation
Add escalation
Raise priority
Add priority
$ git diff --stat main...feature/escalation
 escalation.py | 1 +
 priority.py   | 1 +
 2 files changed, 2 insertions(+)
$ git merge-base main feature/escalation | xargs git log -1 --format=%s
Add routes file
```
<!-- /snippet -->

<!-- snippet: gates/g6-predict/p2-answer-b -->
```text
$ git log --format=%s main..feature/escalation
Add escalation
$ git diff --stat main...feature/escalation
 escalation.py | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

Before the repair the pull request lists three commits and two files, because the merge base is still the commit below the squashed branch. After `git rebase --onto main feature/priority feature/escalation` it lists one commit and one file.

**Marking.** 1 point: three subjects. 1 point: two files. 1 point: "Add routes file". 2 points: one subject and one file afterwards.

**Reference.** Chapter 17, sections 17.3, 17.12 and 17.14.

### P3 (5 points)

<!-- snippet: gates/g6-predict/p3-answer -->
```text
$ git check-ignore -v --no-index docs/index.md docs/api/auth.md infra/prod.tf services/billing/api/handler.py README.md
.gitignore:1:*	docs/index.md
.gitignore:1:*	docs/api/auth.md
.gitignore:1:*	infra/prod.tf
.gitignore:1:*	services/billing/api/handler.py
.gitignore:1:*	README.md
```
<!-- /snippet -->

**Git:** line 1 for all five paths. Gitignore matching works on directories first: the catch-all `*` matches the directories `docs`, `infra` and `services`, Git excludes each whole directory and never looks at the files inside, so no later line gets a chance; `README.md` matches only line 1.

**CODEOWNERS, from the documented rules (last matching line wins, one file path at a time):** `docs/index.md` line 2; `docs/api/auth.md` line 1, because `docs/*` does not match nested files; `infra/prod.tf` line 3; `services/billing/api/handler.py` line 4; `README.md` line 1. The answers differ for three paths: `docs/index.md`, `infra/prod.tf` and `services/billing/api/handler.py`.

**Marking.** 3 points for the Git output: all five 3, a candidate who predicts lines 2, 2, 3, 4, 1 (the intuitive answer) earns 0 of these 3 and may still earn the next 2 if it is given as the CODEOWNERS answer. 2 points: the CODEOWNERS answer with `docs/api/auth.md` on line 1 and the reason for the difference.

**Reference.** Chapter 19, section 19.5 (root-cause box "git check-ignore says ...").

### P4 (5 points)

<!-- snippet: gates/g6-predict/p4-answer -->
```text
$ git log -1 --format='author:    %an <%ae>%ncommitter: %cn <%ce>%nsignature: %G?'
author:    Asha Rao <asha@example.com>
committer: Lab User <you@example.com>
signature: N
$ git verify-commit HEAD
[exit status: 1]
$ git cat-file -p HEAD | grep -c "^gpgsig"
0
```
<!-- /snippet -->

The author field is whatever the person who ran `git commit` typed. The committer is the configured identity. `N` means no signature; `git verify-commit` exits with status 1.

**On GitHub (from the textbook):** without vigilant mode the commit has no badge at all, and it is attributed to Asha's account if the email belongs to it. If Asha has enabled vigilant mode, an unsigned commit attributed to her is shown as "Unverified". Neither display proves who made the commit: author fields are assertions. Only a verified signature ties a commit to the holder of a key, and vigilant mode makes the absence of one visible.

**Marking.** 2 points: author Asha, committer Lab User, `N`. 1 point: exit status 1. 2 points: no badge without vigilant mode, Unverified with it, and the conclusion.

**Reference.** Chapter 14B, section 14B.18; Chapter 21B, sections 21B.5 to 21B.7.

---

## Part 3: Hands-on diagnosis

### Variant A

#### Case 1 (12 points): six blocking conditions, 2 points each

Each needs the rule, the layer and the smallest change for both points; one point for a correct finding without the layer or without a workable change.

| # | Blocks because | Rule and layer | Evidence | Local test | Smallest change |
|---|---|---|---|---|---|
| 1 | The required check `build` will never be reported | `required_status_checks` in the repository ruleset | `build.yml` runs on `pull_request` only for `src/**` and `pyproject.toml`; the directory is `ledger/` now, so the workflow is skipped for this pull request, and a skipped workflow leaves its checks pending | `git diff --name-only origin/main...HEAD` against the `paths` list | remove the path filter from the workflow whose check is required, in a separate change by someone who can merge it; correcting `src/**` to `ledger/**` repairs today and leaves the trap for the next documentation-only pull request |
| 2 | Commit 2 is unsigned | `required_signatures` in the organization ruleset. The rule is evaluated on the commits the pull request introduces | Ravi's description | `git log --format='%h %G? %s' origin/main..HEAD` | re-create commit 2 with a signature (a rebase that signs), then `git push --force-with-lease` |
| 3 | "Rebase and merge" cannot satisfy the signature rule | the same rule, together with the method: rebase merges are made "without commit signature verification" | Ravi selected rebase | none | choose squash. Linear history excludes a merge commit, signatures exclude rebase: squash is the only method all layers allow |
| 4 | There is no valid approval | `pull_request` rule: the organization says `dismiss_stale_reviews_on_push: false`, the repository says `true`, and the strictest applies | Asha approved after commit 2; commit 3 was pushed afterwards | none | a new approval after the last push |
| 5 | No code owner has approved | `require_code_owner_review: true` in the repository ruleset, with CODEOWNERS from `main` | by the file, `ledger/totals.py` and `docs/rounding.md` belong to `@acme-pay/maintainers` and `infra/terraform/versions.tf` to `@acme-pay/platform` or `@ravi-acme`. Ravi cannot approve his own pull request; Asha is on `ledger-core`, which owns nothing in effect (case 2) | none | approvals from a member of `maintainers` and a member of `platform` |
| 6 | The branch is not up to date | `strict_required_status_checks_policy: true` | two pull requests were merged since the branch was created | `git merge-base --is-ancestor origin/main HEAD` exits with 1 | update the branch |

**Not blocks:** review threads (none open); `require_last_push_approval` (false in both rulesets); the check `test` (passed).

**Order matters,** and a strong answer says so: every push dismisses approvals, so first re-sign commit 2 and bring the branch up to date in one push, then let the checks run, then collect the approvals, then squash.

**Ravi's question.** A ruleset applies to everyone, organization owners included, unless the actor is on its bypass list; both lists are empty. Being an owner lets him change the rules, which is a different act from merging despite them, and it leaves an audit entry.

**The configuration change.** For block 1: do not require a check whose workflow can be skipped; run the workflow for every pull request and decide inside the job what to do. Not "add Ravi to the bypass list": a bypass switches off every rule of that ruleset for him, including review and signatures, in order to work around one stale path filter.

**Common wrong answers.** "The required check failed" (it never ran). "Squash would be blocked too because GitHub does not sign": GitHub signs the squash commit; it is the unsigned commit on the head branch that blocks. "Asha's approval counts because the organization ruleset does not dismiss": the strictest version applies.

**Reference.** Chapter 18, sections 18.4, 18.5, 18.7, 18.8, 18.10, 18.11 and 18.17; Chapter 17, section 17.5.

#### Case 2 (9 points)

4 points for the six paths (six right 4, five 3, four 2, three 1) and 5 points for five defects with consequence and correction.

The catch-all `*` stands on line 7 of 8 (counting pattern lines). The last matching line wins, and `*` matches every file, so every line above it is dead.

| Path | Deciding line | Requested |
|---|---|---|
| `ledger/totals.py` | `*` | `@acme-pay/maintainers` |
| `docs/rounding.md` | `*` | `@acme-pay/maintainers` |
| `docs/adr/0007-rounding.md` | `*` (and `docs/*` would not match a nested file anyway) | `@acme-pay/maintainers` |
| `infra/terraform/versions.tf` | `/infra/terraform/` | `@acme-pay/platform` and `@ravi-acme` |
| `ledger/migrations/0042_round.sql` | `*`: not the DBA team | `@acme-pay/maintainers` |
| `.github/CODEOWNERS` | `*` | `@acme-pay/maintainers` |

Defects:

1. The general pattern `*` comes after the specific ones and overrides them. Move it to the top.
2. `*.sql` stands after `/ledger/migrations/`. Even with `*` at the top, every migration would go to `ledger-core` and not to `dba`. Order from general to specific.
3. `docs/*` covers only files directly in `docs/`. Use `/docs/`.
4. `!` negation is not supported in CODEOWNERS. The line does not exclude anything; express the exception as a later, more specific line with its own owners.
5. `@acme-pay/docs-guild` has the Read role. An owner needs write access; the line assigns nobody and is reported as an error. Grant the team write access or choose another owner.
6. A second `CODEOWNERS` in the root. GitHub uses the first file it finds, in `.github/`; the root file is never read and misleads people. Delete it.
7. Neither `/.github/` nor the CODEOWNERS file has an owner of its own; anyone whom the catch-all team approves can rewrite the owners and the workflows. Add `/.github/ @acme-pay/maintainers` or a security team as the last line.
8. An individual, `@ravi-acme`, as owner: he cannot approve his own changes, and the line breaks when he leaves. Own by team.

**Reference.** Chapter 19, sections 19.3 to 19.8 and 19.12.

#### Case 3 (9 points)

- **What the server established (2 points).** The request was authenticated: a credential was presented and accepted. The account it belongs to cannot see `acme-pay/ledger`, so GitHub answered 404, by design, to avoid confirming that a private repository exists.
- **Root cause (3 points).** The credential of the wrong account answers. Evidence: the helper for `https://github.com` is `gh auth git-credential`, and `gh auth status` reports `ravi-oss` as the active account. The helper hands Git the token of the active account, the personal one, which has no access to the company's repository. It worked on Friday because the work account was the only one then.
- **Corrections (2 points).** Today: `gh auth switch --user ravi-acme`, then `gh auth status` and `git ls-remote origin` to verify before pushing. For good: give each account its own route, so that the repository and not the last login decides: an SSH key and host alias per account with `url.<alias>.insteadOf` inside a conditional include for the work directory, or over HTTPS one credential per account with `credential.https://github.com.username` in that include. Verify with `ssh -T` on the alias, or with `git ls-remote` in a work and in a personal repository.
- **Alternatives (2 points).** A misspelled or renamed repository: ruled out, the URL is the one that worked on Friday and the repository opens in the browser. A fine-grained token that does not include this repository, or a credential not authorized for the organization's single sign-on: possible in general; here the evidence already names a different account, and both are checked the same way, by finding out which identity answered. Access removed over the weekend: the browser session of the work account still shows the repository.

**Common wrong answers.** "Generate a new token." "Re-clone." "Add the token to the URL", which would also leak it into `.git/config`.

**Reference.** Chapter 16, sections 16.4, 16.5, 16.13 and 16.17 to 16.20.

### Variant B

#### Case 1 (12 points)

Five blocking conditions and one contradiction, 2 points each.

| # | Blocks because | Rule and layer | Evidence | Smallest change |
|---|---|---|---|---|
| 1 | Both approvals are gone | `dismiss_stale_reviews_on_push: true`, release ruleset | Ravi pushed at 10:40, after both approvals | two new approvals |
| 2 | The last push needs an approval from someone other than its pusher | `require_last_push_approval: true`, release ruleset | Ravi pushed last; his own approval cannot cover his push | at least one of the new approvals from a person who is not Ravi; Asha, as the author, cannot approve either |
| 3 | An open review thread | `required_review_thread_resolution: true` | the thread about the variable name | resolve it |
| 4 | `integration` has no result that counts | `required_status_checks`: checks count for runs triggered by `pull_request`, `push` and a few other events; a `workflow_dispatch` run satisfies nothing | "Run workflow" by hand | find out why the workflow did not start for the pull request (a path or branch filter is the usual cause) and make it run for the event |
| 5 | Linear history | the classic rule on `release/*`, which matches `release/2.4` and is evaluated together with the rulesets | administrator's description | see the contradiction |
| 6 | **The contradiction.** The ruleset allows only the method `merge`; the classic rule requires linear history, which forbids a merge commit | aggregation: the strictest of each rule applies, and both apply | the two layers | no pull request can satisfy both. Decide once: either remove linear history from the classic rule (better: delete the classic rule and move what is wanted into the ruleset), or allow `squash` in the ruleset |

**Blocks nothing:** `ruleset-signing-trial.json`. Its enforcement status is `disabled`. A disabled ruleset protects nothing; the point to raise is that it looks like protection in a settings page. Also not a block: `strict_required_status_checks_policy` is false, so the branch need not be up to date; and `unit` is green.

**Asha's question.** The permission comes from the bypass list of the release ruleset: her team is on it in the mode "for pull requests only", which lets a member merge a pull request despite unmet rules, with a recorded bypass. It does not reach the classic rule: classic rules do not bind administrators by default, and Asha has the Write role, so the classic requirements (one approval, linear history) still apply to her. Advice for the hotfix: the bypass exists for this situation, and using it is defensible only if what it skips is actually done another way. Here that means: a second person reads the third commit now, the thread is closed, and the integration suite's manual run is on the head commit. Then record the bypass in the incident log, and repair the two configuration faults (the check that does not start, the contradiction) the same day so that the next hotfix does not need one. "Merge now because the box allows it" earns no points.

**Common wrong answers.** Listing the signing ruleset as a block. Missing that a push dismisses both approvals. "The manual run is green, so the check is satisfied."

**Reference.** Chapter 18, sections 18.3, 18.4, 18.5, 18.7, 18.8, 18.11 and 18.14; Chapter 17, section 17.5.

#### Case 2 (9 points)

4 points for the four paths, 5 points for the questions and four defects.

The pull request is judged by the file on `main`, the base branch, not by Ravi's edited version.

| Path | Deciding line on `main` | Required owner |
|---|---|---|
| `.github/CODEOWNERS` | `*` | `@acme-pay/maintainers` |
| `services/payouts/engine.py` | `*`: the line `/Services/Payouts/` has the wrong case and matches nothing | `@acme-pay/maintainers` |
| `services/fx/rates.py` | the second `/services/fx/` line; the first is overridden | `@acme-pay/treasury` |
| `docs/runbooks/payout-failure.md` | `/docs/`: the last line uses a `[a-p]` range, which CODEOWNERS does not support, so it does not match as intended | `@asha-acme` |

- Ravi's new line names `@acme-pay/payouts-core`. It has no effect on this pull request: the base branch decides. It takes effect for pull requests opened after his is merged.
- The change to `.github/CODEOWNERS` is approved by `@acme-pay/maintainers`, through the catch-all. The file that names the reviewers has no owner of its own.
- Defects: (1) wrong case in `/Services/Payouts/`: no match; compare with `git ls-files`. (2) One pattern on two lines: only the later line counts; put both teams on one line. (3) A character range, which is not supported: rewrite with supported forms. (4) A sole individual owner of `/docs/`: Asha cannot approve her own documentation changes, and nobody else is asked; own by team. (5) No owner for `/.github/`. (6) A second file at `docs/CODEOWNERS`, which is never read while `.github/CODEOWNERS` exists.

**Reference.** Chapter 19, sections 19.3 to 19.8 and 19.12.

#### Case 3 (9 points)

- **Who wrote which line (2 points).** `git@github.com: Permission denied (publickey).` is written by the `ssh` client after the server rejected the authentication. The lines from `fatal:` on are Git's: the program it started for the other side exited before the conversation began, and the "access rights" sentence is a generic hint, not a diagnosis.
- **What the server established (2 points).** Nothing about the repository and nothing about Ravi. None of the keys offered belongs to any account, so the connection could not be attached to an account. Authorization, and with it "organization owner", is never reached.
- **Root cause (3 points).** The remote URL uses the host name `github.com`, not the alias. For that name only the `Host *` block applies: `identitiesonly yes` and the single identity file `~/.ssh/id_rsa_2019`, an old key that is not registered. The new work key is configured under `Host github-work`, which this URL never selects. Evidence: the first `ssh -G` listing shows one identity file for `git@github.com`; the second shows the work key first for the alias; `ssh -T git@github-work` succeeds.
- **Corrections (2 points).** In the repository: `git remote set-url origin git@github-work:acme-pay/payouts.git`, verified with `git remote get-url origin` and `git ls-remote origin`. In the user's configuration, for every repository of the organization: `url."git@github-work:acme-pay/".insteadOf "git@github.com:acme-pay/"`, verified with `git ls-remote --get-url origin`, which prints the rewritten URL without connecting.
- **If the message had been `ERROR: Repository not found.`** the server would have authenticated the connection as some account that cannot see the repository: an identity problem one step later. Then `ssh -T` with the same host name tells which account, and the repair is to make the right key answer or to grant access.

**Common wrong answers.** "Ask for access rights." "Add the old RSA key to the account." "Remove `IdentitiesOnly`", which makes the agent offer every key and hides the configuration error.

**Reference.** Chapter 16, sections 16.10, 16.13, 16.17, 16.18 and 16.20.

---

## Part 4: Oral interview

O1 to O4: 3 points for a complete answer with the follow-up, 2 for a correct answer with a weak follow-up, 1 for a definition without mechanism. O5 and O6: 4, 3, 2 or 1 on the same scale, the fourth point for the production consequence.

### O1 (3 points)

**Model answer.** No. Git has branches, commits and merges; it has no pull requests. A pull request is a record in GitHub's database that names a base branch and a head branch and carries the discussion, the reviews and the checks. *Follow-up:* opening one moves no branch. GitHub writes `refs/pull/<n>/head` in the base repository for the head commit and, when the merge is clean, a test merge commit under `refs/pull/<n>/merge`. So `git fetch origin pull/<n>/head:pr-<n>` gets the commits from the base repository; `gh pr checkout <n>` does the same and sets up the branch.

**Weak answer.** "A pull request is a branch." **Reference.** Chapter 15, section 15.2; Chapter 17, section 17.2.

### O2 (3 points)

**Model answer.** The page shows `base..head`. It lists too much when the head reaches commits that the base does not: the branch was started from another feature branch, or that branch was squash-merged or rebase-merged so that its content is in the base and its commits are not; or the base selected in the pull request is not the branch the work started from. *Follow-up:* merging `main` in makes the diff correct, because the merge base moves, and leaves the foreign commits in the list, and with a squash-merged ancestor it usually conflicts. I would replay only my commits with `git rebase --onto main <old base>` and push with `--force-with-lease`, after telling the reviewers, who can compare with `git range-diff`.

**Weak answer.** "GitHub has a bug; close and reopen." **Reference.** Chapter 17, section 17.12.

### O3 (3 points)

**Model answer.** Squash for a service deployed from `main`: one commit per pull request, a linear history, each commit on `main` is a state that passed the checks, and a revert is one command. What I give up: the reviewed commit IDs are not on `main`, bisect stops at the pull request, authorship of individual commits is folded together, and a branch cannot be reused after it was squashed. For a library with long-lived release branches I would weigh merge commits instead. *Follow-up:* squash: `git revert <commit>`. Merge commit: `git revert -m 1 <merge>`, and remember to revert the revert before merging the branch again. Rebase: one revert per commit of the feature, which is why rebase merging makes "remove the feature" harder.

**Weak answer.** "Squash, because it is clean." **Reference.** Chapter 17, sections 17.8 and 17.9.

### O4 (3 points)

**Model answer.** That the holder of a particular private key created exactly this commit object, and that GitHub associates the key with the account. It does not prove that the change is correct, reviewed or benign, or that the key holder was not compromised. *Follow-up:* nothing about the author. Author fields are assertions that anyone can type. I check who pushed it: the pull request, the audit log and the push event name the authenticated account, which is a different fact from the author field. And I would ask why this branch accepts unsigned commits, and whether the CTO has vigilant mode on, which would have marked the commit as Unverified.

**Weak answer.** "That the commit is safe." **Reference.** Chapter 21B, sections 21B.5 to 21B.7; Chapter 14B, section 14B.17.

### O5 (4 points)

**Model answer.** From the outside in. First what the merge box says. Then which rules apply to the base branch from every layer: the repository's `/rules` page for the branch, organization rulesets, a classic rule. Administrators are bound by rulesets unless they are on the bypass list, so "I am an administrator" explains nothing. Then one question per rule, most of them answerable locally: is the branch up to date (`git merge-base --is-ancestor`), are the commits signed (`%G?`), is the history linear, is there an approval after the last push, is a code owner among the approvers, are the threads resolved. *Follow-up:* the workflow that reports the check was skipped by a path filter, a branch filter or `[skip ci]`; the check name in the rule does not match any job name any more, for example after a job was renamed; the check is reported only for another event, such as `push` or a manual run, or the pull request is in a merge queue and the workflow lacks `merge_group`. In production the cost is a hotfix that waits on a check that will never arrive, and the temptation to bypass.

**Weak answer.** "Ask an owner to merge it." **Reference.** Chapter 18, sections 18.5, 18.8 and 18.17.

### O6 (4 points)

**Model answer.** A GitHub App installation token: the app is installed on repository B with read permission on contents, the token lives one hour, belongs to no person and reaches only the installation's repositories. If one repository and read-only is all that is ever needed, a deploy key on B is the simple alternative. Ruled out: the workflow's `GITHUB_TOKEN`, which reaches only repository A; a classic personal token, which reaches every repository its owner can reach and belongs to a person who may leave; a machine user, which costs a seat and needs an owner for its password and second factor. A fine-grained personal token limited to B is acceptable as a stopgap and still belongs to a person. *Follow-up:* a token in a URL is stored in plain text in `.git/config`, is printed by `git remote -v`, travels into logs and backups, and a classic token reaches everything its user reaches. Revoke it first, then clean the URL (with `transfer.credentialsInUrl=die` set, by writing the key directly, because `git remote set-url` refuses to read the bad URL), then review the audit log for its use. Cleaning the file does not un-leak the token.

**Weak answer.** "A personal access token in a secret." **Reference.** Chapter 16, sections 16.6, 16.7 and 16.14.

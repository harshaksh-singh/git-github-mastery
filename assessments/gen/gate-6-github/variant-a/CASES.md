# Gate 6, hands-on, variant A: three cases to diagnose

Everything in this directory was constructed for the gate. No file is the export of a real repository, and the organization `acme-pay` does not exist. The JSON files use the field names of GitHub's REST API for rulesets as the textbook shows them in Chapter 18, section 18.18.

Work on paper. You may use a lab shell to try Git commands on a repository of your own; you may not use GitHub. For every statement about what GitHub does, name the textbook section it rests on.

## Case 1 (12 points): "Why can't I merge?"

**Files:** [`ruleset-org-baseline.json`](ruleset-org-baseline.json) (an organization ruleset; the part that selects repositories is left out of the file, it selects all of them), [`ruleset-main.json`](ruleset-main.json) (a ruleset of the repository `acme-pay/ledger`), [`CODEOWNERS`](CODEOWNERS) (the file at `.github/CODEOWNERS` on `main`), [`ci.yml`](ci.yml) and [`build.yml`](build.yml) (the two workflows of the repository).

**The pull request,** as described by its author, Ravi, who is an organization owner:

> Pull request 214, `fix/rounding` into `main`, in `acme-pay/ledger`. Three commits, all mine:
>
> 1. "Round half to even in the ledger total", changes `ledger/totals.py`. Signed, and GitHub shows it as Verified.
> 2. "Document the rounding rule", changes `docs/rounding.md`. Made on the build server over SSH, where I have no signing key.
> 3. "Raise the Terraform provider pin", changes `infra/terraform/versions.tf`. Signed and Verified.
>
> Asha, who is on the `ledger-core` team, approved after commit 2. I pushed commit 3 afterwards. Two other pull requests were merged into `main` since I branched. No review thread is open.
>
> The merge box shows no green button. The check `test` passed. A check called `build` is listed as "Expected: waiting for status to be reported", and has been for two hours. I selected "Rebase and merge" because we like a linear history.
>
> I am an organization owner. Why can I not merge my own pull request?

**Your task.** List every condition that blocks this merge. For each one give: the rule and the ruleset it comes from; the evidence in the files or in Ravi's description; the local Git command, if one exists, that would test the condition in a clone (Chapter 18, section 18.17); and the smallest change that satisfies it. Then answer Ravi's last question. Finally say which single change to the repository's configuration you would propose so that one of these blocks cannot recur, and why you would not propose "add Ravi to the bypass list".

## Case 2 (9 points): who is asked to review?

**File:** [`CODEOWNERS`](CODEOWNERS), the same file as in case 1. Additional facts: the repository also has a file `CODEOWNERS` in its root, last edited two years ago, that names `@acme-pay/everyone` for `*`. The team `@acme-pay/docs-guild` has the Read role on this repository.

For each of these six changed paths, name the line of `.github/CODEOWNERS` that decides and the owners GitHub requests, according to the documented matching rules:

1. `ledger/totals.py`
2. `docs/rounding.md`
3. `docs/adr/0007-rounding.md`
4. `infra/terraform/versions.tf`
5. `ledger/migrations/0042_round.sql`
6. `.github/CODEOWNERS`

Then list every defect of the file and of its setup that you can find, with the consequence of each and the correction. There are at least five.

## Case 3 (9 points): the push that cannot find the repository

Ravi again, the next morning, from his laptop:

```text
$ git push origin fix/rounding
remote: Repository not found.
fatal: repository 'https://github.com/acme-pay/ledger.git/' not found
```

He adds: "The repository exists, I have it open in the browser. `git pull` worked on Friday. Over the weekend I set up my open-source work on this laptop and signed in with `gh auth login` for my personal account, `ravi-oss`."

The evidence he pasted. The two listings are constructed for the case.

```text
$ git remote -v
origin  https://github.com/acme-pay/ledger.git (fetch)
origin  https://github.com/acme-pay/ledger.git (push)

$ git config list --show-origin | grep -i -e credential -e 'url\.'
file:/Users/ravi/.gitconfig   credential.https://github.com.helper=
file:/Users/ravi/.gitconfig   credential.https://github.com.helper=!/opt/homebrew/bin/gh auth git-credential
```

He also ran `gh auth status`. It reports two accounts for `github.com`: `ravi-oss`, marked as the active account, and `ravi-acme`.

**Your task.** State what the server established before it answered, and why it answered "not found" and not "forbidden". Name the root cause with the evidence line that shows it. Give two different corrections, one that repairs today's push and one that prevents the confusion on this machine for good, and say what you would check after each. Name two other root causes that produce the same message and how the evidence here rules each of them in or out.

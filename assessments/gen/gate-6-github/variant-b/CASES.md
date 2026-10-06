# Gate 6, hands-on, variant B: three cases to diagnose

Everything in this directory was constructed for the gate. No file is the export of a real repository, and the organization `acme-pay` does not exist. The JSON files use the field names of GitHub's REST API for rulesets as the textbook shows them in Chapter 18, section 18.18. The `ssh` listing in case 3 is real output of `labs/gates/g6-evidence.sh`, which reads a configuration file written for the case and connects to nothing.

Work on paper. You may use a lab shell to try Git commands on a repository of your own; you may not use GitHub. For every statement about what GitHub does, name the textbook section it rests on.

## Case 1 (12 points): the hotfix that will not merge

**Files:** [`ruleset-release.json`](ruleset-release.json) and [`ruleset-signing-trial.json`](ruleset-signing-trial.json), both rulesets of the repository `acme-pay/payouts`. The files leave out the target conditions and the bypass list: both rulesets target the branch pattern `release/**/*`.

**Further configuration, described by the repository administrator:**

> - A classic branch protection rule from 2023 still exists for the pattern `release/*`. It requires one approval and linear history. "Do not allow bypassing the above settings" is not selected.
> - The bypass list of the ruleset "payouts: release branches" holds the team `release-managers` in the mode "For pull requests only". 
> - The repository settings allow all three merge methods.

**The pull request,** as described by its author, Asha, who is a member of `release-managers` and has the Write role:

> Pull request 88, `hotfix/payout-rounding` into `release/2.4`. Two commits, both mine. You approved it at 10:00 and Ravi approved it at 10:20. At 10:40 Ravi pushed a third commit to my branch, a typo fix in a comment. One review thread, about a variable name, is still open; I answered it and nobody clicked "Resolve".
>
> Checks: `unit` is green. `integration` did not start for the pull request, so I started that workflow by hand on my branch with "Run workflow", and it is green in the Actions tab. The merge box still lists `integration` as expected.
>
> It is a production hotfix and I want it merged within the hour. The merge box tells me that I am allowed to bypass the rules for this pull request. Should I?

**Your task.** List every condition that blocks this merge, layer by layer: the two rulesets, the classic rule, the repository settings. For each one give the rule, the evidence, and the smallest change that satisfies it. One of the two ruleset files blocks nothing: say which and why. Two of the layers contradict each other in a way that no pull request into `release/2.4` can satisfy: find the contradiction and say how it should be resolved. Then answer Asha's question: where that permission comes from, what using it leaves behind, and what you would advise for this hotfix.

## Case 2 (9 points): the pull request that changes the owners

**File:** [`CODEOWNERS`](CODEOWNERS), the file at `.github/CODEOWNERS` on `main` of `acme-pay/payouts`. Additional facts: a second file exists at `docs/CODEOWNERS`. The ruleset for `main` requires review from code owners. The directory in the repository is `services/payouts/`, in lower case.

Ravi opens pull request 91 into `main`. It changes four paths:

1. `.github/CODEOWNERS` (he adds the line `/services/payouts/ @acme-pay/payouts-core` at the end)
2. `services/payouts/engine.py`
3. `services/fx/rates.py`
4. `docs/runbooks/payout-failure.md`

For each path, name the line that decides, on which version of the file, and the owners whose approval is required. Then answer: can Ravi's pull request be approved by the owners that his new line names? Who has to approve the change to `.github/CODEOWNERS` itself, and what does that tell you about the file? Finally list every defect of the file that you can find, with its consequence and correction. There are at least four.

## Case 3 (9 points): the key that nobody knows

Ravi, on a new laptop:

```text
$ git fetch
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

He adds: "I do have access rights, I am an organization owner. I generated a new key for work last week, added it to my work account, and `ssh -T git@github-work` greets me by name."

```text
$ git remote -v
origin  git@github.com:acme-pay/payouts.git (fetch)
origin  git@github.com:acme-pay/payouts.git (push)
```

<!-- snippet: gates/g6-evidence/01-config -->
```text
$ cat ssh_config
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_acme
  IdentitiesOnly yes

Host *
  IdentityFile ~/.ssh/id_rsa_2019
  IdentitiesOnly yes
```
<!-- /snippet -->

<!-- snippet: gates/g6-evidence/02-resolved -->
```text
# What ssh would use for the host name in the remote URL, and for the alias (-T: no terminal):
$ ssh -T -F ssh_config -G git@github.com | show
user git
hostname github.com
identitiesonly yes
identityfile ~/.ssh/id_rsa_2019
$ ssh -T -F ssh_config -G git@github-work | show
user git
hostname github.com
identitiesonly yes
identityfile ~/.ssh/id_ed25519_acme
identityfile ~/.ssh/id_rsa_2019
```
<!-- /snippet -->

**Your task.** Say which program wrote each line of the error, what the server had established when the connection ended, and why "I am an organization owner" is not relevant to this message. Name the root cause with the evidence lines that show it. Give two corrections, one in the repository and one in the user's Git configuration that covers every repository of the organization, and the command that verifies each without transferring anything. Then explain how the diagnosis would differ if the message had been `ERROR: Repository not found.`

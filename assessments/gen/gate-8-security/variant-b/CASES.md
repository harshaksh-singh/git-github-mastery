# Gate 8, hands-on, variant B: three cases to diagnose

Everything in this directory was constructed for the gate. The workflow file parses as YAML and is insecure on purpose; it is teaching material and must never be run. Every "secret" in the transcripts is an obvious dummy. The Git transcripts are real output of `labs/gates/g8-evidence.sh`, in which a bare repository plays the server; the host `git.example.com` does not exist. Nothing was run on GitHub.

This gate is defensive. You are asked to find weaknesses, explain the mechanism at the level the textbook does, and repair them. You are not asked to write an exploit, and an answer that contains one earns nothing extra.

## Case 1 (12 points): review this workflow before it is merged

**File:** [`publish.yml`](publish.yml). The repository is public and receives pull requests from forks. Its workflow `ci` runs on `push` and on `pull_request`, builds the package and uploads it as the artifact `dist`. The pull request that adds `publish.yml` says: "Publishes the package whenever CI is green. Keeps the cloud key out of the CI workflow."

**Your task.** Review it with the checklist of Chapter 21A, section 21A.19. List the findings in order of severity. For each: the lines, what an outsider controls, what that reaches (token, secret, cloud identity), and the repair. State under which conditions this job should run at all, as an `if:` in words, and where the human gate belongs. Then say what the permission `id-token: write` is for, and what the workflow should have done with it.

## Case 2 (9 points): a key in a notebook output

Asha: "My evaluation notebook had an API key in a cell output. I noticed it, cleared the outputs in a second commit, and the pull request was squash-merged, so `main` never had the key. The branch was deleted after the merge. There is nothing to clean up, right?"

What you find from a clone that never had her branch:

<!-- snippet: gates/g8-evidence/b2-evidence -->
```text
# A fresh look from a clone that never had the branch:
$ git log --all --format='%h %s' -S'dummy-eval-api-key'
$ git ls-remote origin
8f33d614db5a405c73062f210593e97878a7ada0	HEAD
8f33d614db5a405c73062f210593e97878a7ada0	refs/heads/main
c40a65e859b5307bd7027c0f52294c92580a7404	refs/pull/12/head
$ git fetch -q origin 'refs/pull/*/head:refs/remotes/origin/pr/*'
$ git log --all --format='%h %an: %s' -S'dummy-eval-api-key'
c40a65e Asha Rao: Clear notebook outputs
af43e19 Asha Rao: Add evaluation notebook
$ git for-each-ref --format='%(refname)' --contains "$(git log --all --format=%H -S'dummy-eval-api-key' | tail -1)"
refs/remotes/origin/pr/12
```
<!-- /snippet -->

**Your task.**

1. Say what the evidence shows: where the key is and is not, and why the first search found nothing while the second found two commits.
2. Asha's four statements are each true. Explain why "nothing to clean up" still does not follow, with the layer (Git or GitHub) for each step of the argument.
3. Write the response in order. Say which step makes most of the others optional, whether rewriting `main` would achieve anything, and what only the hosting service can remove.
4. Give two preventions that would have stopped the key before it reached the server, one in the repository and one on the platform.

## Case 3 (9 points): the clone on the build server

During an audit of the build server you look at one of the clones that the nightly job uses:

<!-- snippet: gates/g8-evidence/b3-evidence -->
```text
$ git remote -v
origin	https://ci-bot:dummy-token-not-real-0000@git.example.com/acme/reports.git (fetch)
origin	https://ci-bot:dummy-token-not-real-0000@git.example.com/acme/reports.git (push)
$ grep -n url .git/config
9:	url = https://ci-bot:dummy-token-not-real-0000@git.example.com/acme/reports.git
$ git config get --show-origin transfer.credentialsInUrl || echo "transfer.credentialsInUrl is not set"
transfer.credentialsInUrl is not set
```
<!-- /snippet -->

**Your task.** Name what is wrong and every place the credential has travelled to because it was stored this way. Give the response in order. The audit recommends `transfer.credentialsInUrl=die` for the build server: say what that setting does, and predict what happens when someone then tries to repair this clone with `git remote set-url`. Give the command that does repair it. Finally say how the nightly job should authenticate instead, and what limits the damage if that credential leaks too.

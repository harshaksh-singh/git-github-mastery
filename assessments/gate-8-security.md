# Gate 8: Security

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026, as the textbook cites them. Nothing in this gate was run on GitHub, and no GitHub output is shown. The transcripts are real output of `labs/gates/g8-predict.sh`; every "secret" in them is an obvious dummy. This file contains no answers. The answer key is for the examiner; do not open it before the gate is scored, and not at all if you failed and will take variant B.

**Taken after** Module 31. **Covers** the security of GitHub Actions, repository security and the response to a leaked secret: Chapters [21A](../textbook/ch21a-actions-security.md) and [21B](../textbook/ch21b-repository-security-incident-response.md), with the token sections of Chapter [16](../textbook/ch16-authentication.md).

**This gate is defensive.** Every item asks you to find a weakness, explain its mechanism, repair it and prevent it. No item asks for an attack, and none is to be answered with one. Never use a real credential in an answer or a lab; write `dummy-...`.

**Pass rule.** 90 points or more out of 100, and at least 70% in every part. How a gate is taken, timed and scored is in the [README](README.md).

| Part | Points | Minimum to pass the part | Time |
|---|---|---|---|
| 1 Concepts | 30 | 21 | 45 minutes, closed book |
| 2 Prediction | 20 | 14 | 25 minutes, no terminal |
| 3 Hands-on diagnosis | 30 | 21 | 60 minutes, on paper |
| 4 Oral interview | 20 | 14 | 20 minutes, spoken, no terminal |

---

## Part 1: Concepts (30 points)

Six questions, 5 points each. Answer in writing, in five to ten sentences. Say for each statement whether it is about Git, GitHub or GitHub Actions.

### C1 (5 points)

Every job receives a token. Explain what that token is, what decides what it may do, what a workflow without a `permissions` key gets (the answer has a date in it), and what you write at the top of every workflow and why. Then state what changes for the token and for secrets when the run was triggered by a `pull_request` event from a fork.

### C2 (5 points)

`pull_request_target` "is safe exactly as long as it never executes the stranger's code". Explain the sentence: which copy of the workflow runs, with which token and which secrets, and what turns it into the weakness known as a "pwn request". Name two other triggers with the same property. Describe the two safe designs for a team that needs to label, comment on or report results for pull requests from forks. What did `actions/checkout` change in 2026 about this?

### C3 (5 points)

A step contains `run: echo "Title: ${{ github.event.pull_request.title }}"`. Explain, without writing an attack, why this is a weakness: when the expression is replaced, by what, and what the shell then receives. Name four values an outsider controls. Give the repair and say why it works. Which tools find this pattern before a human does?

### C4 (5 points)

`uses: owner/action@v4` and `uses: owner/action@<40 hexadecimal characters>`: explain what each one promises about the code that will run next month. What can a compromised action reach? What does a pin not protect against, and who keeps pins current? Name two platform policies that turn these rules from a convention into something GitHub enforces.

### C5 (5 points)

A developer commits a file with a credential, pushes, notices, deletes the file in a new commit, pushes again, then force-pushes the branch back to before the first commit, then makes the repository private. After each of the four actions, say where the credential still is and who can reach it. State the one action that ends the exposure, and why "the exposure window starts at the first push and does not end at deletion".

### C6 (5 points)

Give the six steps of the response to a leaked secret in order, with one sentence each on what goes wrong when the step is skipped or done out of order. Then describe a whole-history rewrite as an operation: what changes in the repository, what it does to open pull requests, tags, signatures and other people's clones, what on GitHub survives it and who can remove that, and when the sources say a rewrite is not warranted.

---

## Part 2: Prediction (20 points)

Four items, 5 points each. No terminal. Write the output you expect and one sentence of mechanism for each prediction.

### P1 (5 points)

<!-- snippet: gates/g8-predict/p1-setup -->
```text
$ git init -q notifier
$ cd notifier
$ printf 'def notify(msg):\n    print(msg)\n' > notify.py && git add . && git commit -q -m 'Add notifier'
$ mkdir config && printf 'SMTP_PASSWORD=dummy-not-a-real-password\n' > config/prod.env
$ git add . && git commit -q -m 'Add production settings'
$ printf 'def notify(msg):\n    print("[notify]", msg)\n' > notify.py && git commit -q -am 'Prefix notifications'
$ git rm -q config/prod.env && git commit -q -m 'Remove secrets from the repository'
```
<!-- /snippet -->

Predict:

1. The exit status of `git grep -c 'dummy-not-a-real' HEAD`.
2. The subjects listed by `git log --format=%s -S'dummy-not-a-real'`.
3. The subjects of the commits whose tree contains `config/prod.env`.
4. The output of `git show HEAD~1:config/prod.env`.

### P2 (5 points)

<!-- snippet: gates/g8-predict/p2-setup -->
```text
$ git init -q toolbox
$ cd toolbox
$ mkdir .githooks && printf '#!/bin/sh\necho tracked hook\n' > .githooks/pre-commit && chmod +x .githooks/pre-commit
$ printf '*.ipynb filter=strip\n' > .gitattributes
$ git add . && git commit -q -m "Add hooks directory and attributes"
$ printf '#!/bin/sh\necho local hook\n' > .git/hooks/post-checkout && chmod +x .git/hooks/post-checkout
$ git config set core.hooksPath .githooks
$ git config set filter.strip.clean 'sed s/x/y/'
$ cd ..
$ git clone -q toolbox copy
$ cd copy
```
<!-- /snippet -->

Predict, in `copy/`:

1. The output of `git ls-files`.
2. The number of files in `.git/hooks` that do not end in `.sample`.
3. The exit status of `git config get core.hooksPath` and of `git config get filter.strip.clean`.
4. The output of `git check-attr filter notebook.ipynb`, and whether any filter program runs when a notebook is added in `copy/`.

### P3 (5 points)

<!-- snippet: gates/g8-predict/p3-setup -->
```text
# server.git has three commits on main: "Add app", "Add key file", "Extend app".
# you/ and asha/ are clones of it, both up to date. In you/:
$ git rebase -q --onto HEAD~2 HEAD~1 main
$ git log --format=%s main
Extend app
Add app
$ git push -q --force-with-lease origin main
# In asha/, who was not told. She commits and pulls, then pushes:
$ printf 'notes\n' > ../asha/NOTES.md && git -C ../asha add NOTES.md && git -C ../asha commit -q -m 'Add notes'
$ git -C ../asha pull -q --no-rebase
$ git -C ../asha push -q origin main
```
<!-- /snippet -->

Predict, on the server:

1. The shape of `git log --graph --format=%s main`: every commit by its subject, and the number of parents of the tip.
2. The output of `git log --format=%s -S'dummy-not-a-real' main`.
3. The exit status of `git cat-file -e main:keys.env`.

Say in one sentence why the server accepted Asha's push although yours had needed a forced update.

### P4 (5 points)

<!-- snippet: gates/g8-predict/p4-setup -->
```text
$ cat ../server.git/hooks/pre-receive
#!/bin/sh
# Reject a push when the new tip of a ref contains the pattern.
while read old new ref; do
  if git grep -q 'dummy-not-a-real' "$new" --; then
    echo "rejected: $ref contains a secret pattern" >&2
    exit 1
  fi
done
$ printf 'TOKEN=dummy-not-a-real-token\n' > .env && git add .env && git commit -q -m 'Add environment file'
```
<!-- /snippet -->

Now `git push origin main` runs. Predict:

1. Whether the push is accepted, and its exit status.

Then:

<!-- snippet: gates/g8-predict/p4-setup-b -->
```text
$ git rm -q .env && git commit -q -m 'Remove environment file'
```
<!-- /snippet -->

2. Predict whether `git push origin main` is accepted now, and its exit status.
3. Predict the output of `git log --format=%s -S'dummy-not-a-real' main` on the server afterwards.
4. Say what the guard should have examined instead.

---

## Part 3: Hands-on diagnosis (30 points)

On paper: three cases built from a workflow file, described situations and real Git evidence. Variant A is the first attempt; variant B is for a retake and is not to be opened before.

| | Variant A | Variant B (retake) |
|---|---|---|
| The cases | [`variant-a/CASES.md`](gen/gate-8-security/variant-a/CASES.md) | [`variant-b/CASES.md`](gen/gate-8-security/variant-b/CASES.md) |
| The files | `assessments/gen/gate-8-security/variant-a/` | `assessments/gen/gate-8-security/variant-b/` |

| Case | Points | Graded on |
|---|---|---|
| 1 Workflow review | 12 | 2 points per finding, up to six: lines, what an outsider controls, what it reaches, repair; the safe design |
| 2 A leaked secret | 9 | reading of the evidence; the ordered response with the first action first; the rewrite decision with its consequences |
| 3 The aftermath | 9 | what happened and why it was possible; ordered repair; prevention |

An answer to case 2 or 3 in which the credential is not revoked or rotated before anything else earns at most half of that case. An answer that contains a working attack earns nothing for the item.

---

## Part 4: Oral interview (20 points)

Six questions, asked one at a time by the examiner, who then asks the follow-up. Answer aloud in one to two minutes each. O1 to O4 are worth 3 points each, O5 and O6 are worth 4 points each.

### O1 (3 points)

How do you secure GitHub Actions in a repository you have just taken over? *Follow-up:* you may change three things today. Which three, and why those?

### O2 (3 points)

How do you investigate a leaked secret? *Follow-up:* someone proposes to rewrite history and force-push within the hour. What do you ask before agreeing?

### O3 (3 points)

A colleague says: "The repository is private, so a secret in it is fine." Respond. *Follow-up:* where do secrets belong, and what replaces a long-lived cloud key in a deployment job?

### O4 (3 points)

Why is masking of secrets in logs not a security boundary? *Follow-up:* which jobs of a workflow should be able to read a deployment secret at all, and what enforces that?

### O5 (4 points)

An action that half your workflows use by version tag is reported as compromised: its tags were moved to a commit that prints secrets into logs. What do you do in the first hour, and how do you find out whether you were affected? *Follow-up:* what would have limited the damage beforehand?

### O6 (4 points)

Is it safe to clone a repository from an unknown author? *Follow-up:* a contractor sends you a zip file of a project "with the Git history included". What is different, and what do you do with it?

---

## Score sheet

| Item | Max | Score | | Item | Max | Score |
|---|---|---|---|---|---|---|
| C1 | 5 | | | P1 | 5 | |
| C2 | 5 | | | P2 | 5 | |
| C3 | 5 | | | P3 | 5 | |
| C4 | 5 | | | P4 | 5 | |
| C5 | 5 | | | **Prediction** | **20** | |
| C6 | 5 | | | H case 1 | 12 | |
| **Concepts** | **30** | | | H case 2 | 9 | |
| O1 to O4 | 12 | | | H case 3 | 9 | |
| O5, O6 | 8 | | | **Hands-on** | **30** | |
| **Oral** | **20** | | | **Total** | **100** | |

Pass: total 90 or more, Concepts 21 or more, Prediction 14 or more, Hands-on 21 or more, Oral 14 or more.

## Remediation map

After scoring, restudy the sections of every item on which you lost more than a third of the points, redo the labs of that module, and take the gate again with variant B of the hands-on part.

| Item | Restudy | Lab module |
|---|---|---|
| C1 | Chapter 21A, sections 21A.3 and 21A.4 | 29 |
| C2 | Chapter 21A, sections 21A.4 and 21A.5 | 29 |
| C3 | Chapter 21A, sections 21A.6 and 21A.14 | 29 |
| C4 | Chapter 21A, sections 21A.7 and 21A.8 | 29 |
| C5 | Chapter 21B, section 21B.10 | 30 |
| C6 | Chapter 21B, sections 21B.14, 21B.16 and 21B.19 | 31 |
| P1 | Chapter 21B, sections 21B.10 and 21B.11 | 30 |
| P2 | Chapter 21B, sections 21B.2 and 21B.4 | 30 |
| P3 | Chapter 21B, sections 21B.17 and 21B.18 | 31 |
| P4 | Chapter 21B, section 21B.12 | 30 |
| Case 1 | Chapter 21A, sections 21A.3 to 21A.13 and 21A.19 | 29 |
| Case 2 | Chapter 21B, sections 21B.10, 21B.11, 21B.14, 21B.16 and 21B.19 | 31 |
| Case 3 | Chapter 21B, section 21B.18 (variant A); Chapter 16, sections 16.6, 16.7 and 16.14 (variant B) | 31, 20 |
| O1 | Chapter 21A, sections 21A.2, 21A.8, 21A.16 and 21A.19 | 29 |
| O2 | Chapter 21B, sections 21B.11 and 21B.14 | 31 |
| O3 | Chapter 21B, sections 21B.8 and 21B.10; Chapter 21A, sections 21A.9 and 21A.10 | 30 |
| O4 | Chapter 21A, sections 21A.9 and 21A.13 | 29 |
| O5 | Chapter 21A, sections 21A.7, 21A.8 and 21A.18 | 29 |
| O6 | Chapter 21B, sections 21B.2 to 21B.4 | 30 |

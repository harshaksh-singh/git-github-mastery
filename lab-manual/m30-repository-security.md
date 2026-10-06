# Module 30 labs: Repository and supply-chain security

> **Baseline.** Git 2.55.0 and GitHub CLI 2.88.1 on macOS; GitHub facts as of 1 October 2026. Read [Chapter 21B](../textbook/ch21b-repository-security-incident-response.md), sections 21B.9 to 21B.13, first. Every transcript under "Expected output" is real output of a replay script in `labs/ch21b/`. Nothing in this file was run against GitHub: what GitHub does is described from its documentation, with the link, and you record what you actually see. Every secret here is a dummy such as `DUMMY-KEY-not-a-real-secret-12345`, spelled so that no scanner pattern matches it. Never use a real credential in a lab.

## How these labs work

Labs 30.1 and 30.2 have a local Part A in the lab shell and a Part B on GitHub. Lab 30.3 is local only.

```bash
bash labs/ch21b/setup-30-1-push-check.sh       # build the starting state (run again to start over)
labs/shell m30-1                               # open the isolated lab shell in that sandbox
labs/run ch21b/lab-30-1-push-check             # optional: replay the lab and print its transcript
```

> **Run every Part B in your normal shell, not in `labs/shell`.** The lab shell switches off the system Git configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub.

Part B uses the public practice repository `YOUR-ORG/practice-repo` and your clone `~/git-mastery/practice-repo` from the [Module 19 labs](m19-github-platform.md). It is public, which is why secret scanning, push protection and Dependabot cost nothing there (Chapter 21B, section 21B.12).

Differences between your terminal and the transcripts: lines such as `[exit status: 1]` are printed by the replay scripts (by hand, run `echo $?`); lines that start with `#` are notes from a script; `$LAB` stands for the lab root. The setup scripts use the fixed lab clock, so the commits they create have the IDs printed here; commits you make by hand get the real time and other IDs.

Answers to the Questions are in [solutions/m30-lab-answers.md](../solutions/m30-lab-answers.md). Write your own first.

## Lab 30.1: Push protection, and what a push-time check catches

### Objective

See what a check at push time does and does not do: first with a `pre-receive` hook on a bare "server" that you control, then with GitHub push protection on your practice repository. Learn why deleting the file in a new commit does not unblock a push, and fix a blocked push the documented way.

### Prerequisites

- Chapter 21B, sections 21B.10 and 21B.12. Chapter 9 for `git rebase -i`.
- For Part B: the practice repository of Module 19 and a working `gh auth status`.

### Setup

```bash
bash labs/ch21b/setup-30-1-push-check.sh
labs/shell m30-1
```

The script builds `server.git` (bare), your clone `triage` with one pushed commit, and `kit/` with two small hooks.

### Commands

**Part A, in the lab shell.**

Step 1. Read the server hook and install it.

```bash
cat kit/pre-receive
cp kit/pre-receive server.git/hooks/pre-receive
cd triage
```

Step 2. Commit a `.env` with the dummy key, then an unrelated commit, and push.

```bash
printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env
git add .env && git commit -q -m 'Add local settings'
printf 'def priority(ticket):\n    return 1 if "outage" in ticket else 3\n' > priority.py
git add priority.py && git commit -q -m 'Add ticket priority'
git log --oneline origin/main..main
git push
git status -sb
```

Step 3. The secret is in the earlier of two unpushed commits. Edit that commit and keep the later one. In the editor that opens, change `pick` to `edit` on the first line, save and close.

```bash
git rebase -i origin/main
git rm -q --cached .env
printf '.env\n' > .gitignore && git add .gitignore
git commit -q --amend --no-edit
git rebase --continue
```

Step 4. Check what would be pushed, then push.

```bash
git log --oneline origin/main..main
git grep -c DUMMY-KEY $(git rev-list origin/main..main) || echo "no commit to be pushed contains the key"
git push
```

Step 5. Push a secret that has no recognizable shape.

```bash
printf 'db_password: correct-horse-battery-staple\n' > database.yaml
git add database.yaml && git commit -q -m 'Add database settings'
git push
```

**Part B, in your normal shell.** Enable secret scanning and push protection on the practice repository and read the setting back. Reading `security_and_analysis` needs admin permission on the repository ([REST: repositories](https://docs.github.com/en/rest/repos/repos)).

```bash
gh repo edit YOUR-ORG/practice-repo --enable-secret-scanning --enable-secret-scanning-push-protection
gh api repos/YOUR-ORG/practice-repo --jq '.security_and_analysis'
```

Then push the dummy file on a branch, and delete the branch afterwards:

```bash
cd ~/git-mastery/practice-repo
git switch -c lab-30-1
printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > lab-30-1.env
git add lab-30-1.env && git commit -m 'Lab 30.1: dummy value'
git push -u origin lab-30-1
git push origin --delete lab-30-1
git switch main && git branch -D lab-30-1
```

### Expected output

Step 1 and 2. The hook scans every commit the push would introduce. The push is declined and nothing reaches the server:

<!-- snippet: ch21b/lab-30-1-push-check/01-install -->
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
$ cd triage
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-30-1-push-check/02-blocked -->
```text
$ printf 'LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345\n' > .env
$ git add .env && git commit -q -m 'Add local settings'
$ printf 'def priority(ticket):\n    return 1 if "outage" in ticket else 3\n' > priority.py
$ git add priority.py && git commit -q -m 'Add ticket priority'
$ git log --oneline origin/main..main
3f376a8 Add ticket priority
49384d9 Add local settings
$ git push 2>&1
remote: push declined: refs/heads/main: commit 3f376a8 contains a secret pattern        
To ../server.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to '../server.git'
[exit status: 1]
$ git status -sb
## main...origin/main [ahead 2]
```
<!-- /snippet -->

Step 3. In the transcript the replay tool plays the editor and prints the todo list before and after:

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

Step 4 and 5:

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

**Part B, described from documentation; not run by the author.** The `--jq` output should show `secret_scanning` and `secret_scanning_push_protection` with `status` `enabled`. The push of `lab-30-1.env` is expected to be **accepted**: push protection blocks recognized provider patterns, and the dummy value matches none ([about push protection](https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection), [supported patterns](https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns)). That acceptance is the lesson of step 5 on the real platform. If a push *is* blocked, the documentation describes `remote:` lines that name the secret type and, for each occurrence, the commit and `path:line`, plus a URL where the pusher can choose a bypass reason; after a bypass the push must be repeated within three hours ([push protection from the command line](https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/working-with-push-protection-from-the-command-line)). Do not create a real token to see the block.

### What happened internally

`git push` sent the new objects to the server, which placed them in a quarantine area and ran `pre-receive` before updating any ref. The hook listed the commits that no existing ref reaches (`git rev-list <new> --not --all`) and searched each one's tree. A non-zero exit made `receive-pack` discard the quarantined objects and report `pre-receive hook declined`; `origin/main` in your clone did not move, as `git status -sb` showed. The rebase in step 3 replaced both unpushed commits: `49384d9` became `1668a86` without `.env`, and `3f376a8` became `dc90cbc` because its parent changed. The server never saw the first pair.

### Checkpoint

- The first decline names commit `3f376a8`, "Add ticket priority", which did not add the secret. Explain why before reading the answers.
- After step 4, `git -C ../server.git log --oneline main` shows three commits and no `.env` in any of them.

### Failure scenario

Answer a block by deleting the file in a new commit.

```bash
printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml
git add debug.yaml && git commit -q -m 'Add debug settings'
git push 2>&1 | head -1
git rm -q debug.yaml && git commit -q -m 'Remove debug settings'
git push 2>&1 | head -1
git log --oneline origin/main..main
```

<!-- snippet: ch21b/lab-30-1-push-check/06-failure -->
```text
# Failure scenario: the block is answered by deleting the file in a new commit.
$ printf 'token: DUMMY-TOKEN-not-a-real-secret-67890\n' > debug.yaml
$ git add debug.yaml && git commit -q -m 'Add debug settings'
$ git push 2>&1 | head -1
remote: push declined: refs/heads/main: commit 8060cdc contains a secret pattern        
$ git rm -q debug.yaml && git commit -q -m 'Remove debug settings'
$ git push 2>&1 | head -1
remote: push declined: refs/heads/main: commit 8060cdc contains a secret pattern        
$ git log --oneline origin/main..main
69172f4 Remove debug settings
8060cdc Add debug settings
```
<!-- /snippet -->

The second push is declined for the same commit. The push would still deliver `8060cdc`, whose snapshot contains the token.

### Recovery

Neither commit is wanted and neither was pushed, so drop both. `git reset --hard` discards uncommitted work too; `git status -s` first.

```bash
git reset -q --hard origin/main
git log --oneline -3
git status -sb
git push
```

<!-- snippet: ch21b/lab-30-1-push-check/07-recovery -->
```text
$ git reset -q --hard origin/main
$ git log --oneline -3
ffe1804 Add database settings
dc90cbc Add ticket priority
1668a86 Add local settings
$ git status -sb
## main...origin/main
$ git push 2>&1
Everything up-to-date
[exit status: 0]
```
<!-- /snippet -->

### Verification

```bash
cd ..
git -C server.git log --oneline main
git -C server.git grep -l -E 'DUMMY-(KEY|TOKEN)' $(git -C server.git rev-list --all) | wc -l
git -C server.git grep -n password main
```

<!-- snippet: ch21b/lab-30-1-push-check/08-verification -->
```text
$ cd ..
$ git -C server.git log --oneline main
ffe1804 Add database settings
dc90cbc Add ticket priority
1668a86 Add local settings
c3cf659 Add ticket router
$ git -C server.git grep -l -E 'DUMMY-(KEY|TOKEN)' $(git -C server.git rev-list --all) | wc -l
       0
$ git -C server.git grep -n password main
main:database.yaml:1:db_password: correct-horse-battery-staple
```
<!-- /snippet -->

No dummy key or token on the server, and one password that the check never saw. For Part B: the branch `lab-30-1` no longer exists on GitHub (`git ls-remote --heads origin`), and the two settings read `enabled`.

### Questions

1. Why did the first decline name a commit that did not add the secret?
2. GitHub's documented fix for a secret in an earlier commit is an interactive rebase with `edit`. Why can the same fix not be used once the commit has been pushed and fetched by others?
3. The password in step 5 passed. Name two controls that could have caught it, and say at which point each acts.
4. You pushed the dummy file to a branch on GitHub and deleted the branch. Is the file gone from GitHub? What does Chapter 21B, section 21B.10 say?
5. Push protection for users is enabled on your account by default. Would it have protected a push to a *private* repository without Secret Protection?

## Lab 30.2: A Dependabot configuration

### Objective

Write `.github/dependabot.yml` for a Python project with a Dockerfile and workflows, check it locally, and enable Dependabot alerts, security updates and version updates on the practice repository.

### Prerequisites

- Chapter 21B, section 21B.13.
- Part A uses Python with PyYAML for a parse check (`python3 -c 'import yaml'` must succeed). If it does not, read Part A and do Part B.

### Setup

Part A needs only an empty directory in the lab shell:

```bash
labs/shell m30-2
git init inventory-api && cd inventory-api
mkdir -p .github
```

### Commands

**Part A, in the lab shell.**

Step 1. Create `.github/dependabot.yml` in your editor with the content shown under "Expected output". The keys are from the [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference): `version: 2`, `updates`, and per entry `package-ecosystem`, `directory` and `schedule.interval` are required; `groups` and `cooldown` are optional.

```bash
cat .github/dependabot.yml
```

Step 2. Create `check.py` with the content shown under "Expected output" and run it.

```bash
cat check.py
python3 check.py .github/dependabot.yml
```

**Part B, in your normal shell.** Copy the file into the practice repository, adjust the ecosystems to what the repository contains (use `pip` if it has `requirements.txt` and no `uv.lock`), and open a pull request.

```bash
cd ~/git-mastery/practice-repo
git switch -c dependabot-config
mkdir -p .github
cp /path/to/your/dependabot.yml .github/dependabot.yml
git add .github/dependabot.yml
git commit -m "Configure Dependabot version updates"
git push -u origin dependabot-config
gh pr create --fill
```

Enable Dependabot alerts and security updates in the repository's settings. The documentation places them on the "Advanced Security" settings page ([configuring Dependabot security updates](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-security-updates)); labels change, so follow the page. After merging, read the result back:

```bash
gh api repos/YOUR-ORG/practice-repo --jq '.security_and_analysis.dependabot_security_updates'
gh pr list --repo YOUR-ORG/practice-repo --app dependabot
```

### Expected output

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

**Part B, described from documentation; not run by the author.** Version updates start once the file is on the default branch. Dependabot opens pull requests per ecosystem, at most five open version-update pull requests at a time unless configured otherwise, and since 14 July 2026 a new release is proposed only after a default cooldown of three days; security updates are not subject to the limit or the cooldown ([options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), [changelog](https://github.blog/changelog/2026-07-14-dependabot-version-updates-introduce-default-package-cooldown/)). A practice repository with few dependencies may receive no pull request for days. Dependabot signs its commits.

### What happened internally

Locally nothing happened beyond a YAML parse: `dependabot.yml` is configuration for a GitHub service, and Git treats it as a file. On GitHub the dependency graph parses the manifests on the default branch; alerts compare that graph with the GitHub Advisory Database; security updates open a pull request to the minimum patched version; version updates follow the schedule in the file. The `github-actions` entry with directory `/` makes Dependabot look in `.github/workflows` and at an `action.yml` in the root.

### Checkpoint

- `check.py` prints three lines with `missing=[]`.
- You can say which of the three Dependabot features the file configures, and which two it does not.

### Failure scenario

Save the file one level too high, and leave out the schedule.

```bash
printf 'version: 2\nupdates:\n  - package-ecosystem: "pip"\n    directory: "/"\n' > dependabot.yml
python3 check.py dependabot.yml
git status -s
```

<!-- snippet: ch21b/lab-30-2-dependabot/03-failure -->
```text
# A common slip: the file saved one level too high, and an ecosystem without a schedule.
$ printf 'version: 2\nupdates:\n  - package-ecosystem: "pip"\n    directory: "/"\n' > dependabot.yml
$ python3 check.py dependabot.yml
pip             /    -       missing=['schedule']
$ git status -s
?? .github/
?? check.py
?? dependabot.yml
```
<!-- /snippet -->

The check reports the missing key. It cannot report the other mistake: a `dependabot.yml` in the repository root is in the wrong place, and the reference states that the file must be in the `.github` directory.

### Recovery

```bash
rm dependabot.yml
git add .github/dependabot.yml && git commit -q -m 'Configure Dependabot version updates'
git ls-files
```

<!-- snippet: ch21b/lab-30-2-dependabot/04-recovery -->
```text
$ rm dependabot.yml
$ git add .github/dependabot.yml && git commit -q -m 'Configure Dependabot version updates'
$ git ls-files
.github/dependabot.yml
```
<!-- /snippet -->

### Verification

Locally: `git ls-files` lists `.github/dependabot.yml` and nothing else (`check.py` stays untracked). On GitHub: the file is on the default branch, `gh api` reports `dependabot_security_updates` as `enabled`, and `gh pr list --app dependabot` lists Dependabot's pull requests once it has opened any. Record what you see, and where in the interface GitHub reports the status of the configuration file; the author could not observe it.

### Questions

1. Which of alerts, security updates and version updates does `dependabot.yml` switch on?
2. Chapter 21A tells you to pin actions by commit SHA. What does that do to Dependabot *alerts* for actions, and what keeps the pins current?
3. Why does the `github-actions` entry use the directory `/` and not `/.github/workflows`?
4. An old configuration contains `reviewers:`. What happened to that option, and what replaces it?
5. Why might a cooldown on version updates be a security control and not only a convenience?

## Lab 30.3: Scan a full history for planted secrets

### Objective

Find every planted dummy secret in a repository with built-in commands: at the tip, in the history of every ref, and in commits that only the reflog still reaches. Establish for each one whether it was pushed.

### Prerequisites

- Chapter 21B, sections 21B.10 and 21B.11. Chapter 14A for the pickaxe; Chapter 13 for reflogs.

### Setup

```bash
bash labs/ch21b/setup-30-3-history-scan.sh
labs/shell m30-3
cd ragdesk
```

The script builds `server.git` and your clone `ragdesk`, a retrieval-augmented helpdesk service. Three dummy secrets are planted. You are told only their shape: `DUMMY-KEY-...` or `DUMMY-TOKEN-...`, lower-case words and a number.

### Commands

Step 1. The tip.

```bash
git status -sb
git grep -n -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
```

Step 2. When did it enter, and who committed it?

```bash
git log --format='%h %ad %an: %s' --date=iso-local -S'DUMMY-KEY-not-a-real-secret-12345'
first=$(git log --format=%h --diff-filter=A -- .env); echo $first
git show --stat --format="%h %s" $first
```

Step 3. Every ref: by diff, by snapshot, by distinct value.

```bash
git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
git grep -l -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | cut -d: -f2 | sort | uniq -c
git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
```

Step 4. Scope: which refs contain each leak?

```bash
git branch -a --contains $first
git tag --contains $first
nb=$(git log --all --format=%h -1 -- notebooks/rerank-debug.ipynb); echo $nb
git branch -a --contains $nb
```

### Expected output

<!-- snippet: ch21b/lab-30-3-history-scan/01-tip -->
```text
$ cd ragdesk
$ git status -sb
## main...origin/main [ahead 1]
$ git grep -n -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
.env:1:LLM_API_KEY=DUMMY-KEY-not-a-real-secret-12345
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-30-3-history-scan/02-when-and-who -->
```text
$ git log --format='%h %ad %an: %s' --date=iso-local -S'DUMMY-KEY-not-a-real-secret-12345'
0805fd8 2026-09-07 10:10:00 +0530 Lab User: Add staging settings
$ first=$(git log --format=%h --diff-filter=A -- .env); echo $first
0805fd8
$ git show --stat --format="%h %s" $first
0805fd8 Add staging settings

 .env          | 2 ++
 settings.yaml | 3 +++
 2 files changed, 5 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-30-3-history-scan/03-every-ref -->
```text
$ git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'
54093fe Add rerank debugging notebook
0805fd8 Add staging settings
$ git grep -l -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | cut -d: -f2 | sort | uniq -c
   6 .env
   1 notebooks/rerank-debug.ipynb
$ git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all) | sort | uniq -c
   6 DUMMY-KEY-not-a-real-secret-12345
   1 DUMMY-TOKEN-not-a-real-secret-67890
```
<!-- /snippet -->

<!-- snippet: ch21b/lab-30-3-history-scan/04-scope -->
```text
$ git branch -a --contains $first
* main
  remotes/origin/feature/streaming
  remotes/origin/main
$ git tag --contains $first
v0.2.0
$ nb=$(git log --all --format=%h -1 -- notebooks/rerank-debug.ipynb); echo $nb
54093fe
$ git branch -a --contains $nb
  remotes/origin/exp/rerank
```
<!-- /snippet -->

### What happened internally

`git grep` without a revision searched the tracked files of the working tree. `git log -S` compared each commit with its parent and kept the commits in which the count of the string changed. `git rev-list --all` printed every commit reachable from any ref under `refs/`, and `git grep <pattern> <commit>...` searched each commit's tree, so the count of 6 for `.env` is the number of snapshots that contain the file, not the number of times it was committed: the blob exists once. The notebook leak sits on `origin/exp/rerank`, a remote-tracking branch with no local branch, which is why only `--all` found it.

### Checkpoint

You have found two distinct values. The setup said three. Before reading on, write down where a commit can exist in a clone without being reachable from any ref.

### Failure scenario

The scan with `--all` is taken for a scan of everything.

```bash
git reflog -3
git log --oneline --all -S'24680'
git log --oneline --reflog -S'24680'
```

<!-- snippet: ch21b/lab-30-3-history-scan/05-failure -->
```text
# The scan above looked at every ref. Is that every commit in this clone?
$ git reflog -3
7cba387 HEAD@{0}: commit (amend): Add smoke test
94cd897 HEAD@{1}: commit: Add smoke test
d4b8762 HEAD@{2}: checkout: moving from exp/rerank to main
$ git log --oneline --all -S'24680'
$ git log --oneline --reflog -S'24680'
94cd897 Add smoke test
```
<!-- /snippet -->

`--all` means all refs. The commit `94cd897` was replaced by `git commit --amend`; no ref reaches it, and it is still in the object database, held by the reflog.

### Recovery

Extend the scan to commits that reflogs reach, then answer the question that decides severity: was it pushed?

```bash
git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all --reflog) | sort | uniq -c
old=$(git rev-parse --short "HEAD@{1}"); echo $old
git show $old:smoke_test.py | head -1
git branch -r --contains $old
git -C ../server.git cat-file -t $old
```

<!-- snippet: ch21b/lab-30-3-history-scan/06-recovery -->
```text
$ git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' $(git rev-list --all --reflog) | sort | uniq -c
   7 DUMMY-KEY-not-a-real-secret-12345
   1 DUMMY-KEY-not-a-real-secret-24680
   1 DUMMY-TOKEN-not-a-real-secret-67890
$ old=$(git rev-parse --short "HEAD@{1}"); echo $old
94cd897
$ git show $old:smoke_test.py | head -1
HEADERS = {"X-Api-Key": "DUMMY-KEY-not-a-real-secret-24680"}
# Was that commit ever pushed? Ask which remote-tracking branches contain it:
$ git branch -r --contains $old
$ git -C ../server.git cat-file -t $old 2>&1
fatal: Not a valid object name 94cd897
```
<!-- /snippet -->

No remote-tracking branch contains it and the server does not have the object. This leak never left the machine: the amend before the push was the cheap fix of Chapter 21B, section 21B.12. The other two were pushed and need the response of Module 31.

### Verification

```bash
git rev-list --all | wc -l
git rev-list --all --reflog | wc -l
```

<!-- snippet: ch21b/lab-30-3-history-scan/07-verification -->
```text
$ git rev-list --all | wc -l
      11
$ git rev-list --all --reflog | wc -l
      12
```
<!-- /snippet -->

Twelve commits against eleven: the difference is the amended one. Your findings table should have three rows: value, file, first commit, refs that contain it, pushed or not.

### Questions

1. `git log -S` printed one commit for the key and `git grep` over all commits printed six snapshots. What does each number mean?
2. Why did `git log --all` not find the third secret, and which objects would even `--reflog` miss?
3. The notebook token is on a branch that was never merged. Is it less exposed than the key on `main`?
4. Why is `git branch -r --contains` only evidence about what *your clone* knows of the server?
5. You are asked to scan 400 repositories. What do the built-in commands lack that a dedicated scanner has?

# V177: .gitignore and .gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository

- **Part.** 8, Professional practice
- **Module.** 33
- **Planned minutes.** 24
- **Prerequisites.** V012, V090, V176
- **Textbook sections.** [Chapter 28](../../textbook/ch28-ai-ml-workflows.md), sections 28.9, 28.10 and 28.12
- **Demo scripts.** `labs/ch28/ml-ignore.sh`, `labs/ch28/hooks-vs-ci.sh`, `labs/ch28/project-skeleton.sh`

## HOOK

**[ON SCREEN]** Two questions from a CTO. "The clone takes eleven minutes. Why?" And: "The pre-commit hooks block large files. How did a 900 kB dump reach `main`?"

The first answer: a checkpoint was committed two years ago and "deleted", and every clone still carries it. The ignore rule that was added afterwards changed nothing about that.

The second answer is five words long: a hook that is not installed does not run. The engineer who pushed the dump never skipped anything. Her clone had no hook.

Both failures have the same shape. A safeguard existed, and it was not in force at the moment and in the place where the mistake was made.

## INTRODUCTION

This video is about putting safeguards in force: ignore rules, attributes, hooks, and the layout of the repository itself. You have the mechanisms already. From V012: ignore rules and the already-tracked trap. From V090: `--no-verify`, `core.hooksPath`, and why hooks cannot enforce policy. Today those mechanisms meet model weights, data sets and evaluation dumps.

Three demos. An ignore file for an ML project, and the checkpoint that was tracked before the rule existed. A hook and a CI script that run the same checks, and three commits, of which the hook stops one. And the finished repository of `docqa`, read in the order of its history, because the order is part of the design.

The tools named today, pre-commit and the scanners, are not installed in the lab; their configuration is shown from their documentation and not run. The checks you see running are a standard-library stand-in.

## LEARNING OBJECTIVES

After this video you can:

1. Write the ignore and attribute rules of an ML project and find which rule decides a path.
2. Fix a checkpoint that is tracked although its pattern is ignored, and say what the fix leaves in history.
3. Explain what a local pre-commit hook guarantees and three ways a commit bypasses it.
4. Back every hook with a CI check.
5. Build the professional AI project repository of section 28.12 from an empty folder.

## CONCEPT

**Ignore rules and attributes, in one sentence.** Ignore rules keep generated and large files from being added by accident, attributes say how tracked files are converted and merged, and neither is a security control.

**[ON SCREEN]** Assembled, not authoritative.

The course's research found no authoritative, maintained `.gitignore` template for ML projects. GitHub's Python template covers interpreter, packaging, environment and tool caches and contains nothing ML-specific. The file you will see is assembled from that template and from each tool's documentation of where it writes output. Read it as a starting point and adjust it to the tools you run. The same holds for the attributes file and for the layout.

Why each group in the ignore file exists. The data directory, because data is versioned by reference. Weight formats, because one stray `git add .` after training would otherwise commit a checkpoint. `wandb/`, `mlruns/` and `mlflow.db`, because the trackers write there by default. `outputs/` and `multirun/`, because Hydra creates a directory per run. `.env`, because that is where local credentials go. Editor and operating-system files are deliberately absent: they belong in each developer's global ignore file, `core.excludesFile`, not in every project.

**Three rules.**

Rule 1: ignore patterns never affect files that are already tracked. The manual defines ignore files as specifying "intentionally untracked files". The index decides what is tracked, not `.gitignore`.

Rule 2: drivers are named in `.gitattributes` and defined in configuration. A committed attribute that names a driver nobody configured is a silent no-op, or a hard failure when the filter is required. That was V175 in one sentence.

Rule 3: an ignore file is not a security control. It prevents accidents by people who use `git add` without `-f`. It does nothing about a file committed before the rule existed, a file added with `--force`, or a secret pasted into a tracked file.

**Hooks, in one sentence.** A hook gives the author feedback in seconds; only a check that runs where the author cannot skip it is a control.

**The framework.** pre-commit, version 4.6.2 of August 2026, manages hooks declared in a committed file. `pre-commit install` installs the Git hook into the clone, `pre-commit run --all-files` is the documented CI usage, and `rev` must be an immutable tag or commit.

**[ON SCREEN]** A typical configuration for an ML repository, assembled from the tools' READMEs with the versions in the report. Not run here.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-added-large-files    # default threshold 500 kB
      - id: detect-private-key
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.9
    hooks:
      - id: ruff-check
      - id: ruff-format
  - repo: https://github.com/kynan/nbstripout
    rev: 0.9.1
    hooks:
      - id: nbstripout
```

```bash
pre-commit install            # once per clone: writes .git/hooks/pre-commit
pre-commit run --all-files    # what CI runs
```

Add one secret scanner. The report notes that the gitleaks README now describes the project as feature complete, with future releases limited to security patches, so check the state of whichever scanner you choose. prek, version 0.5.4, is a Rust reimplementation that reads the same configuration; the report collected no benchmarks for it.

**Why "once per clone" is the whole problem.** The report lists the ways a local hook fails open: hooks are not installed by cloning; they are skipped with one flag; and they are bypassed by commits made through the web interface, the API, or an agent's own Git client.

**[ON SCREEN]** The layers, from section 28.10.

| Layer | Runs where | Can the author skip it? | Role |
|---|---|---|---|
| Editor and local hook | the author's clone | yes: not installed, `--no-verify`, another client | fast feedback |
| CI job as a **required** check | GitHub Actions | no, if a ruleset requires it and bypass is restricted | the control for the branch |
| Push protection and push rulesets | GitHub, at push time | only through a logged bypass | stops secrets and oversized files before they are stored |

**GitHub, not Git.** A CI check catches a secret after it has been pushed: the commit is already on the server, and the credential must be rotated. Only a server-side control at push time, push protection, a push ruleset, or a `pre-receive` hook on a server you run, prevents the bytes from arriving. Use CI for policy, and push-time controls for secrets and size.

**The layout, in one sentence.** A good layout makes the rules of this chapter the path of least resistance: there is an obvious place for everything that belongs in Git and an ignored place for everything that does not.

No single authoritative layout exists. Two reference points are well documented: Cookiecutter Data Science v2, and the Python Packaging Authority's description of the trade-off between the flat and `src/` layouts, without a blanket recommendation. The tree in this video is the course's assembly for an LLM application.

## MENTAL MODEL

Think of three fences at increasing distance from the author.

The first fence is at the desk: the ignore file, the filter, the hook. It is close, fast and friendly, and the author can step over it, or may never have had it built.

The second fence is at the gate of the branch: a required check in CI. The author cannot step over it. But by the time it is reached, the commit is already on the server.

The third fence is at the door of the server: push protection and push rulesets. It is the only one that keeps bytes from arriving.

Where the picture breaks: fences are independent, and these should not be. The first and second fence should run the same code, so that they cannot disagree about the rules. You will see that in the demo: one script, called by the hook and by CI.

And one sentence for the layout: rules first, files second. Each safeguard precedes the thing it guards, so there is no window in which a mistake can enter history.

## DIAGRAM

**[DIAGRAM]** The tree of section 28.12. Build it top down, in four groups: the rule files, the package and tests, the reviewed inputs, and the directories that hold only pointers or nothing.

```text
docqa/
|-- .gitignore              what must never be added by accident (section 28.9)
|-- .gitattributes          line endings, the notebook filter, pointers merged as binary
|-- README.md               what the project is, and the commands a new clone must run once
|-- pyproject.toml          package metadata and dependency ranges
|-- requirements.lock       exact versions (uv.lock in a real project); committed (section 28.8)
|-- Dockerfile              the serving image; base image passed in pinned by digest
|-- .dockerignore           keeps .git, .env, data and runs out of the build context
|-- src/docqa/              the importable package: all logic that deserves tests lives here
|-- tests/                  unit tests; fast, no network, no secrets
|-- configs/                evaluation and model settings; reviewed like code
|-- prompts/                prompt templates, one file per version; reviewed like code
|-- evals/                  the evaluation entry point; writes a run record (section 28.7)
|-- notebooks/              exploration; committed without outputs (section 28.4)
|-- data/                   README and *.ref pointers only; the data itself is ignored
|-- models/                 README and *.ref pointers only; weights are ignored
|-- tools/                  repository tooling: filter, checks, pointer tool, run recorder
|-- hooks/                  shared Git hooks, enabled per clone with core.hooksPath
|-- ci/                     the one script CI runs, runnable locally
`-- runs/                   local run outputs; ignored (a tracker holds the durable copy)
```

Say what the lab does not create and a real repository on GitHub should have: `.github/workflows/` for CI; `.github/CODEOWNERS` so that changes to workflows, lock files, prompts and the `Dockerfile` get a named reviewer; `.github/dependabot.yml`; `SECURITY.md`; a licence; and `.env.example` listing the variable names a developer must set, with no values.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch28/ml-ignore`.

**Step 1: which rule matched?** `git check-ignore -v` answers with the file, the line and the pattern. 🟢 SAFE.

```bash
git check-ignore -v data/raw/tickets.csv data/processed/train.parquet models/v1/model.safetensors checkpoints/epoch-3.ckpt runs/r1/metrics.json wandb/debug.log .env
git check-ignore data/raw/tickets.csv.ref data/README.md .env.example
git check-ignore -v data/raw/tickets.csv.ref data/README.md .env.example
```

Predict: the pointer file is under `data/`, and `/data/**` ignores everything below `data/`. Is the pointer ignored?

<!-- snippet: ch28/ml-ignore/01-which-rule -->
```text
$ git check-ignore -v data/raw/tickets.csv data/processed/train.parquet models/v1/model.safetensors checkpoints/epoch-3.ckpt runs/r1/metrics.json wandb/debug.log .env
.gitignore:17:/data/**	data/raw/tickets.csv
.gitignore:17:/data/**	data/processed/train.parquet
.gitignore:23:/models/**	models/v1/model.safetensors
.gitignore:28:*.ckpt	checkpoints/epoch-3.ckpt
.gitignore:34:/runs/	runs/r1/metrics.json
.gitignore:35:wandb/	wandb/debug.log
.gitignore:12:.env	.env
# The pointer, the README and the example file are not ignored: no output, exit status 1.
$ git check-ignore data/raw/tickets.csv.ref data/README.md .env.example
[exit status: 1]
# With -v, Git names the last matching pattern even when it is a negation (it starts with "!"):
$ git check-ignore -v data/raw/tickets.csv.ref data/README.md .env.example
.gitignore:19:!/data/**/*.ref	data/raw/tickets.csv.ref
.gitignore:20:!/data/README.md	data/README.md
.gitignore:14:!.env.example	.env.example
```
<!-- /snippet -->

The data rules use a pattern worth understanding. `/data/**` ignores everything below `data/`. `!/data/**/` re-includes the directories, which is necessary because Git does not look inside an ignored directory, so no later rule could re-include a file in it. `!/data/**/*.ref` then re-includes the pointer files. Note the last command: with `-v`, `check-ignore` prints the matching pattern even when it is a negation, and exits 0. A line whose pattern starts with an exclamation mark means "not ignored".

<!-- snippet: ch28/ml-ignore/02-status -->
```text
$ git status --short
?? .env.example
?? data/
$ git status --short --ignored | grep "^!!"
!! .env
!! checkpoints/
!! data/processed/
!! data/raw/tickets.csv
!! models/
!! notebooks/
!! runs/
!! wandb/
```
<!-- /snippet -->

`git status --short --ignored` shows what is on disk and ignored, with two exclamation marks.

**Step 2: the checkpoint that was tracked before the rule.** 🟢 SAFE: two commits. Predict: after `*.ckpt` is in the ignore file, what does `git status` say when the checkpoint is retrained?

```bash
git add classifier.ckpt && git commit -q -m "Add trained classifier"
printf '*.ckpt\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore checkpoints'
git ls-files
git check-ignore -v classifier.ckpt
git check-ignore -v --no-index classifier.ckpt
git status --short
```

<!-- snippet: ch28/ml-ignore/03-tracked-before-rule -->
```text
# A checkpoint was committed before anybody wrote a rule for it:
$ git add classifier.ckpt && git commit -q -m "Add trained classifier"
$ printf '*.ckpt\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore checkpoints'
$ git ls-files
.gitattributes
.gitignore
README.md
classifier.ckpt
pyproject.toml
requirements.lock
src/docqa/__init__.py
src/docqa/classify.py
tests/test_classify.py
$ git check-ignore -v classifier.ckpt
[exit status: 1]
$ git check-ignore -v --no-index classifier.ckpt
.gitignore:1:*.ckpt	classifier.ckpt
# The rule matches the path, and Git keeps tracking the file: retraining shows up as a change.
$ git status --short
 M classifier.ckpt
```
<!-- /snippet -->

The pattern matches the path; `--no-index` shows that. And Git goes on tracking the file. Retraining shows up as a modification.

**Step 3: untrack it.** 🟡 CAUTION: `git rm --cached <path>` removes the path from the index and leaves the file on disk. The next commit records a deletion, and a colleague who pulls that commit has the file deleted from their working tree. Preview with `git status`; undo before committing with `git restore --staged`.

```bash
git rm --cached classifier.ckpt
git commit -q -m "Stop tracking the checkpoint"
git status --short --ignored
git log --oneline -- classifier.ckpt
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep ckpt
```

Predict the last line: is the blob still in the repository?

<!-- snippet: ch28/ml-ignore/04-untrack -->
```text
$ git rm --cached classifier.ckpt
rm 'classifier.ckpt'
$ git commit -q -m "Stop tracking the checkpoint"
$ git status --short --ignored
!! classifier.ckpt
# Untracked from now on. History is unchanged: every clone still downloads the blob.
$ git log --oneline -- classifier.ckpt
04154c0 Stop tracking the checkpoint
a4fc927 Add trained classifier
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep ckpt
blob 262144 classifier.ckpt
```
<!-- /snippet -->

**[PAUSE]** Untracked from now on, and the history is untouched: the 262,144-byte blob is still reachable, so every clone still downloads it. That is the eleven-minute clone of the hook. Removing it from history is a rewrite, with everything that implies for a shared repository: V167 and V168. For a secret, rotation comes first.

**[TERMINAL]** Replay `labs/run ch28/hooks-vs-ci`. The checks of this project are a stand-in for the hooks on the slide: file size, private keys, environment files, weight files, notebooks with outputs.

**Step 4: the hook blocks.**

```bash
cat hooks/pre-commit
git config get core.hooksPath
git switch -q -c feature/deploy-script
git add deploy
git commit -m "Add deploy key for the staging box"
```

<!-- snippet: ch28/hooks-vs-ci/01-hook-blocks -->
```text
$ cat hooks/pre-commit
#!/bin/sh
# Shared pre-commit hook. Enable it once per clone: git config set core.hooksPath hooks
exec python3 tools/checks.py --staged
$ git config get core.hooksPath
hooks
$ git switch -q -c feature/deploy-script
$ mkdir deploy && printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy/id_deploy
$ git add deploy
$ git commit -m "Add deploy key for the staging box"
index deploy/id_deploy: contains a private key
checks: 1 file version(s) examined, 1 problem(s)
[exit status: 1]
```
<!-- /snippet -->

The hook did its job: the commit was refused before the key reached any history. The key is a fake that says so.

**Step 5: one flag.** 🟡 CAUTION: `git commit --no-verify` commits without the pre-commit and commit-msg hooks.

```bash
git commit -q --no-verify -m "Add deploy key for the staging box"
git push -q -u origin feature/deploy-script
```

<!-- snippet: ch28/hooks-vs-ci/02-no-verify -->
```text
# One flag skips the hook:
$ git commit -q --no-verify -m "Add deploy key for the staging box"
[exit status: 0]
$ git push -q -u origin feature/deploy-script
```
<!-- /snippet -->

`--no-verify` is not a loophole. It is a documented option, and there are honest uses for it. A control that the controlled person can switch off is not a control.

**Step 6: a clone has no hook.** Predict what `git config get core.hooksPath` prints in Asha's fresh clone.

```bash
git clone -q ../server.git ../docqa-asha && cd ../docqa-asha
git config get core.hooksPath
git switch -q -c feature/eval-dump
wc -c < evals/dump.json
git add evals/dump.json && git commit -q -m "Add evaluation dump for debugging"
git push -q -u origin feature/eval-dump
```

<!-- snippet: ch28/hooks-vs-ci/03-clone-has-no-hook -->
```text
$ git clone -q ../server.git ../docqa-asha && cd ../docqa-asha
$ git config get core.hooksPath
[exit status: 1]
$ git switch -q -c feature/eval-dump
$ wc -c < evals/dump.json
  900011
$ git add evals/dump.json && git commit -q -m "Add evaluation dump for debugging"
$ git push -q -u origin feature/eval-dump
```
<!-- /snippet -->

Asha never skipped anything. Her clone has no `core.hooksPath`, because configuration does not travel, so no hook ran. This is the answer to the second question of the hook.

**Step 7: the same checks, where they cannot be skipped.**

```bash
cat ci/check.sh
sh ci/check.sh origin/main
```

<!-- snippet: ch28/hooks-vs-ci/04-ci -->
```text
# CI checks out each pushed branch and runs the same script over the range it adds:
$ cat ci/check.sh
#!/bin/sh
# Everything CI runs, runnable locally: sh ci/check.sh <base>
# <base> is the commit the branch started from (default: origin/main).
status=0
# 1. Every file version the branch adds, including ones a later commit removed again.
python3 tools/checks.py --range "${1:-origin/main}..HEAD" || status=1
# 2. The whole snapshot that would be merged.
python3 tools/checks.py --tree HEAD || status=1
if python3 -m unittest discover -s tests > /dev/null 2>&1; then echo "tests: ok"; else echo "tests: FAILED"; status=1; fi
exit $status
$ sh ci/check.sh origin/main
27e79a4 evals/dump.json: larger than 500000 bytes (900011)
checks: 1 file version(s) examined, 1 problem(s)
HEAD evals/dump.json: larger than 500000 bytes (900011)
checks: 25 file version(s) examined, 1 problem(s)
tests: ok
[exit status: 1]
$ git switch -q feature/deploy-script
$ sh ci/check.sh origin/main
8ca3417 deploy/id_deploy: contains a private key
checks: 1 file version(s) examined, 1 problem(s)
HEAD deploy/id_deploy: contains a private key
checks: 25 file version(s) examined, 1 problem(s)
tests: ok
[exit status: 1]
$ git switch -q main
$ sh ci/check.sh origin/main~3
checks: 11 file version(s) examined, 0 problem(s)
checks: 24 file version(s) examined, 0 problem(s)
tests: ok
[exit status: 0]
```
<!-- /snippet -->

Two design points. The hook and CI run the same code, `tools/checks.py`, so they cannot disagree about the rules. And the CI script checks two things: every file version the branch adds, with `--range`, which catches a file that was committed and removed again within the branch and is therefore still in history; and the final snapshot, with `--tree`. Both read blobs from Git, never the working tree, so they judge what is in history. On Asha's branch the script names the dump. On the other branch it names the key. On `main` it passes.

**[TERMINAL]** Replay `labs/run ch28/project-skeleton`: `docqa`, as Lab 33.1 builds it from an empty folder.

**Step 8: what Git tracks, and what it does not.**

<!-- snippet: ch28/project-skeleton/01-tracked -->
```text
$ git ls-files
.dockerignore
.gitattributes
.gitignore
Dockerfile
README.md
ci/check.sh
configs/eval.json
data/README.md
data/raw/tickets.csv.ref
evals/run_eval.py
hooks/pre-commit
models/README.md
models/embedder.bin.ref
notebooks/01-error-analysis.ipynb
prompts/answer.v1.txt
pyproject.toml
requirements.lock
src/docqa/__init__.py
src/docqa/classify.py
tests/test_classify.py
tools/checks.py
tools/dataref.py
tools/nbstrip.py
tools/runinfo.py
```
<!-- /snippet -->

<!-- snippet: ch28/project-skeleton/03-ignored -->
```text
# On disk but deliberately not in Git:
$ git status --short --ignored
!! data/raw/tickets.csv
!! models/embedder.bin
!! runs/
$ git check-ignore -v data/raw/tickets.csv models/embedder.bin runs/baseline/run.json
.gitignore:17:/data/**	data/raw/tickets.csv
.gitignore:23:/models/**	models/embedder.bin
.gitignore:34:/runs/	runs/baseline/run.json
```
<!-- /snippet -->

Twenty-four tracked paths, and three ignored ones on disk: the data, the weights and the run outputs. Compare with the tree diagram.

**Step 9: the history, read from the bottom.**

<!-- snippet: ch28/project-skeleton/02-history -->
```text
$ git log --oneline --decorate
aa18ad2 (HEAD -> main, tag: v0.1.0) Add serving image definition and model pointer
8a681ec Add evaluation config, prompt and run recorder
1117838 Version the ticket data set by reference
6be6418 Add notebook filter and the error-analysis notebook
ef4b558 Add repository checks, shared hook and CI entry point
8484ac0 Add package skeleton, lock file and tests
426268a Add ignore rules and attributes before any content
```
<!-- /snippet -->

The ignore rules and attributes are the first commit, `426268a`, before any content exists that they should have caught. The checks and the hook arrive before the first notebook. The notebook filter arrives in the same commit as the first notebook. The pointer tool arrives with the first data. Each safeguard precedes the thing it guards. A repository that adds `.gitignore` in commit forty has thirty-nine commits to audit.

**Step 10: pointers and attributes.**

<!-- snippet: ch28/project-skeleton/04-pointers -->
```text
$ cat data/raw/tickets.csv.ref
{
  "path": "tickets.csv",
  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
  "size": 432
}
$ cat models/embedder.bin.ref
{
  "path": "embedder.bin",
  "sha256": "7daca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2",
  "size": 65536
}
$ find ../datastore -type f | sort
../datastore/sha256/22/26b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e
../datastore/sha256/7d/aca2095d0438260fa849183dfc67faa459fdf4936e1bc91eec6b281b27e4c2
```
<!-- /snippet -->

<!-- snippet: ch28/project-skeleton/05-attributes -->
```text
$ cat .gitattributes
# Line endings: normalize text to LF in the repository on every platform
* text=auto
*.sh text eol=lf

# Notebooks enter the repository without outputs (driver: tools/nbstrip.py, see README)
*.ipynb filter=nbstrip

# Pointer files must never be converted or merged line by line
*.ref text eol=lf merge=binary
$ git check-attr -a notebooks/01-error-analysis.ipynb data/raw/tickets.csv.ref
notebooks/01-error-analysis.ipynb: text: auto
notebooks/01-error-analysis.ipynb: filter: nbstrip
data/raw/tickets.csv.ref: merge: binary
data/raw/tickets.csv.ref: text: set
data/raw/tickets.csv.ref: eol: lf
```
<!-- /snippet -->

Three decisions are in the attributes file. `* text=auto` normalizes line endings in the repository for every contributor. `*.ipynb filter=nbstrip` names the notebook filter. And `merge=binary` on pointer files tells Git never to combine two pointers line by line: a pointer whose hash came from one side and whose size came from the other names nothing. `git check-attr -a` shows which attributes apply to a path.

<!-- snippet: ch28/project-skeleton/06-ignore-file -->
```text
$ cat .gitignore
# Python (a subset of GitHub's Python template)
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ruff_cache/
build/
dist/
*.egg-info/

# Secrets and machine-local settings
.env
.env.*
!.env.example

# Data is versioned by reference: only pointers and the README are tracked
/data/**
!/data/**/
!/data/**/*.ref
!/data/README.md

# Model weights live in the model store, whatever directory they land in
/models/**
!/models/README.md
!/models/*.ref
*.pt
*.pth
*.ckpt
*.safetensors
*.onnx
*.gguf

# Experiment trackers and run outputs
/runs/
wandb/
mlruns/
mlflow.db
outputs/
multirun/

# Notebook autosave copies
.ipynb_checkpoints/
```
<!-- /snippet -->

**Step 11: what a clone must do.** Predict three things a fresh clone lacks.

<!-- snippet: ch28/project-skeleton/07-clone-setup -->
```text
# What a clone has, and what it does not have:
$ git clone -q . ../docqa-asha && cd ../docqa-asha
$ git config get filter.nbstrip.clean
[exit status: 1]
$ git config get core.hooksPath
[exit status: 1]
$ python3 tools/dataref.py verify
missing  data/raw/tickets.csv  (pointer sha256:2226b23c455b)
missing  models/embedder.bin  (pointer sha256:7daca2095d04)
[exit status: 1]
```
<!-- /snippet -->

No filter, no hook path, no data. This is why the README of `docqa` opens with the commands a new clone runs once, and why CI repeats the checks. A bootstrap script that runs those commands is worth having. It is a convenience and still not a control.

## COMMON MISTAKES

1. **Adding an ignore rule for a file that is already tracked.** Root cause: the index decides what is tracked; ignore files only describe intentionally untracked files.
2. **Believing `git rm --cached` shrinks the repository.** Root cause: it changes the index and the next commit; the blob stays reachable in history and every clone still downloads it.
3. **Treating the pre-commit hook as enforcement.** Root cause: the hook is per-clone configuration that is not installed by cloning, is skipped by one flag, and never runs for commits made through another client.
4. **Different rules in the hook and in CI.** Root cause: two implementations of the same policy drift apart, so a commit passes one and fails the other.
5. **Relying on CI to keep secrets out.** Root cause: CI runs after the push, so the bytes are already on the server and the credential has to be rotated.

## PRODUCTION EXAMPLE

A team starts a new retrieval project by copying an old repository and deleting what it does not need. Within a month the old problems are back: a checkpoint in history, a `.env` that was committed once, notebooks with outputs.

For the next project the lead builds the repository in the order of the history you saw. The first commit contains only the ignore file and the attributes file. The second contains the package skeleton and the lock file. The third adds one script of checks, a hook that calls it, and a CI entry point that calls the same script over the range a branch adds and over the final tree. The CI job is made a required check, and push protection is switched on for secrets, because CI comes too late for those. The README begins with the setup commands for a new clone, and the first thing the onboarding buddy asks a new colleague to run is the pair of `git config get` commands that show whether the filter and the hook path are set. Six months later the repository has had outputs stripped by the filter many times and has had the CI check fail three times, each time for a clone that had not been set up.

## PRACTICE EXERCISE

Do Lab 33.1, "Build a professional AI project repository from an empty folder", in [`lab-manual/m33-ai-ml-workflows.md`](../../lab-manual/m33-ai-ml-workflows.md).

Before you make each commit in the lab, say which later mistake this commit guards against and why it has to come before the content it guards. Before the lab's failure scenario, predict which of the three fences will catch the problem and which will not. The lab's questions have answers in a separate file. Attempt them first.

The challenge is Exercise 33.2, Level 2, "Eight paths and one ignore file", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md). Decide each path on paper, then check with `git check-ignore -v`.

## INTERVIEW QUESTION

**[ON SCREEN]** Q364: "What does a local pre-commit hook guarantee? Name three ways a commit reaches the server without passing it, and the control for each."

Answer aloud. Start with the first half, because it is often skipped: say precisely what the hook does guarantee and for whom, which is less than "nothing" and less than "policy". Then give three distinct paths, not three versions of one; the textbook groups them as not installed, switched off, and another client. For each path, name a control and the layer it runs on, and say whether that control acts before or after the bytes reach the server. A strong answer ends with the design principle that keeps the layers from disagreeing.

## RECAP

- Ignore rules prevent accidents with untracked files; they never affect a tracked file and they are not a security control.
- `git rm --cached` stops tracking; the blob stays in history until a rewrite.
- A hook is fast feedback for a clone that has it; three paths go around it: not installed, `--no-verify`, another client.
- The control for a branch is a required CI check that runs the same code as the hook; the control for secrets and size is at push time.
- In a well-built repository each safeguard is committed before the thing it guards, and a new clone still has to be set up.

## HOMEWORK

Read sections 28.9, 28.10 and 28.12. In one repository you work in, run `git check-ignore -v` on three paths you believe are ignored, and the `rev-list --objects` pipeline of step 3 to list the largest blobs in its history. The next video covers CI for ML projects, LLM evaluations on fork pull requests, serving repositories, and AI coding agents.

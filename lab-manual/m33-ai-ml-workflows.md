# Module 33 labs: AI/ML engineering workflows

> **Baseline.** Git 2.55.0 on macOS, and `python3` with its standard library only. Every "Expected output" is real output of a replay script in `labs/ch28/`. Read [Chapter 28](../textbook/ch28-ai-ml-workflows.md) first; each lab names the sections it uses.

## How these labs work

Nothing is installed and nothing touches a network. The tools that an ML team would install (nbstripout, DVC, the pre-commit framework, an experiment tracker) are replaced by short standard-library scripts that show the same mechanisms. Read each script before you use it; none is longer than a hundred lines.

| Script | Stands in for | Mechanism |
|---|---|---|
| `tools/nbstrip.py` | nbstripout | a Git clean filter, and a `--verify` check |
| `tools/dataref.py` | DVC, Git LFS | a pointer file with a checksum; a content-addressed store |
| `tools/checks.py` | hooks run by the pre-commit framework | the same checks from a hook and from CI |
| `tools/runinfo.py`, `evals/run_eval.py` | an experiment tracker's run record | commit, dirty state, data and configuration hashes |

The "data store" is the directory `datastore/` beside the repository. In production it would be a bucket. The "notebook" is a file that `labs/ch28/files/make_notebook.py` wrote the way Jupyter would save it after a run, with outputs; you never need Jupyter.

```bash
bash labs/ch28/setup-33-2-dataset-by-reference.sh   # build (or rebuild) the starting state of Lab 33.2
labs/shell m33-2                                    # open the lab shell in that sandbox, then type the commands
labs/run ch28/lab-33-2-dataset-by-reference         # or: watch the exact replay that the book prints
```

Differences between your terminal and the book that are expected:

- **Commit IDs.** Commits made by a setup script match the book. Commits you make have other IDs. In Lab 33.1 you make every commit, so every ID differs; in Lab 33.3 the recorded commit `aa18ad2` is the setup script's and matches.
- **Checksums match.** SHA-256 values of data files do not depend on time, so pointer files and store paths are identical to the book's.
- **`__pycache__`.** The replays set `PYTHONDONTWRITEBYTECODE=1`. Your shell does not, so `git status --short --ignored` shows a few extra `!! .../__pycache__/` lines. They are ignored files and change nothing.

## Lab 33.1: Build a professional AI project repository from an empty folder

### Objective

Build the `docqa` repository in seven commits, in an order in which every safeguard is committed before the content it guards. Then make the mistake the order cannot prevent: commit a notebook from a clone that has no filter. Detect it with the script CI runs, and repair the unpushed commit.

### Prerequisites

Chapter 28, sections 28.2, 28.4, 28.9, 28.10 and 28.12. Clean filters and `core.hooksPath` from [Chapter 14C](../textbook/ch14c-stash-rerere-attributes-hooks.md); `git commit --amend` and the reflog from Chapters 11 and 13.

### Setup

```bash
bash labs/ch28/setup-33-1-ai-project-repo.sh
labs/shell m33-1
```

Starting state: no repository. `kit/` holds the finished project as plain files, including an executed notebook and a small data file; `datastore/` is empty. Look around first: `find kit -type f | sort`, and read `kit/.gitignore`, `kit/.gitattributes` and `kit/tools/checks.py`.

### Commands

```bash
# 1. Rules first: ignore file and attributes, before any content
git init -q docqa && cd docqa
cp ../kit/.gitignore ../kit/.gitattributes .
git add . && git commit -q -m "Add ignore rules and attributes before any content"

# 2. Package, lock file, tests
cp -R ../kit/pyproject.toml ../kit/requirements.lock ../kit/README.md ../kit/src ../kit/tests .
python3 -m unittest discover -s tests 2>&1 | tail -1
git add . && git commit -q -m "Add package skeleton, lock file and tests"

# 3. Checks, shared hook, CI entry point; enable the hook in this clone
mkdir tools && cp ../kit/tools/checks.py tools/ && cp -R ../kit/hooks ../kit/ci .
git config set core.hooksPath hooks
git add . && git commit -q -m "Add repository checks, shared hook and CI entry point"

# 4. Notebook filter in the same commit as the first notebook
cp ../kit/tools/nbstrip.py tools/
git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
git config set filter.nbstrip.smudge cat
git config set filter.nbstrip.required true
cp -R ../kit/notebooks .
git add . && git commit -q -m "Add notebook filter and the error-analysis notebook"
grep -c output_type notebooks/01-error-analysis.ipynb
git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type

# 5. Data by reference
cp ../kit/tools/dataref.py tools/ && cp -R ../kit/data .
git status --short
python3 tools/dataref.py add data/raw/tickets.csv
git status --short
git add . && git commit -q -m "Version the ticket data set by reference"

# 6. Evaluation, prompt, run recorder
cp ../kit/tools/runinfo.py tools/ && cp -R ../kit/evals ../kit/configs ../kit/prompts .
git add . && git commit -q -m "Add evaluation config, prompt and run recorder"
python3 evals/run_eval.py baseline

# 7. Serving files and the model pointer; tag the result
cp -R ../kit/Dockerfile ../kit/.dockerignore ../kit/models .
python3 tools/dataref.py add models/embedder.bin
git add . && git commit -q -m "Add serving image definition and model pointer"
git tag -a v0.1.0 -m "docqa 0.1.0"

# 8. Inspect
git log --oneline --decorate
git status --short --ignored
git ls-files | wc -l
sh ci/check.sh "$(git rev-list --max-parents=0 HEAD)"
```

### Expected output

<!-- snippet: ch28/lab-33-1-ai-project-repo/01-rules-first -->
```text
$ git init -q docqa && cd docqa
$ cp ../kit/.gitignore ../kit/.gitattributes .
$ git add . && git commit -q -m "Add ignore rules and attributes before any content"
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-1-ai-project-repo/02-package -->
```text
$ cp -R ../kit/pyproject.toml ../kit/requirements.lock ../kit/README.md ../kit/src ../kit/tests .
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ git add . && git commit -q -m "Add package skeleton, lock file and tests"
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-1-ai-project-repo/03-checks -->
```text
$ mkdir tools && cp ../kit/tools/checks.py tools/ && cp -R ../kit/hooks ../kit/ci .
$ git config set core.hooksPath hooks
$ git add . && git commit -q -m "Add repository checks, shared hook and CI entry point"
checks: 3 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

From the third commit on, each `git commit` prints a `checks:` line: the hook is running.

<!-- snippet: ch28/lab-33-1-ai-project-repo/04-notebook -->
```text
$ cp ../kit/tools/nbstrip.py tools/
$ git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
$ git config set filter.nbstrip.smudge cat
$ git config set filter.nbstrip.required true
$ cp -R ../kit/notebooks .
$ git add . && git commit -q -m "Add notebook filter and the error-analysis notebook"
checks: 2 file version(s) examined, 0 problem(s)
$ grep -c output_type notebooks/01-error-analysis.ipynb
3
$ git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type
0
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-1-ai-project-repo/05-data -->
```text
$ cp ../kit/tools/dataref.py tools/ && cp -R ../kit/data .
$ git status --short
?? data/
?? tools/dataref.py
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:2226b23c455b (432 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ git status --short
?? data/
?? tools/dataref.py
$ git add . && git commit -q -m "Version the ticket data set by reference"
checks: 3 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

`git status --short` prints `?? data/` before and after `dataref.py add`, and means two different things. Before, the only untracked file Git will show under `data/` is `README.md`. After, there is also the pointer. The CSV never appears: it is ignored.

<!-- snippet: ch28/lab-33-1-ai-project-repo/06-eval -->
```text
$ cp ../kit/tools/runinfo.py tools/ && cp -R ../kit/evals ../kit/configs ../kit/prompts .
$ git add . && git commit -q -m "Add evaluation config, prompt and run recorder"
checks: 4 file version(s) examined, 0 problem(s)
$ python3 evals/run_eval.py baseline
run baseline: accuracy 0.8000 on 10 examples (commit de800cc)
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-1-ai-project-repo/07-serving -->
```text
$ cp -R ../kit/Dockerfile ../kit/.dockerignore ../kit/models .
$ python3 tools/dataref.py add models/embedder.bin
stored models/embedder.bin as sha256:7daca2095d04 (65536 bytes)
commit the pointer: git add models/embedder.bin.ref
$ git add . && git commit -q -m "Add serving image definition and model pointer"
checks: 4 file version(s) examined, 0 problem(s)
$ git tag -a v0.1.0 -m "docqa 0.1.0"
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-1-ai-project-repo/08-result -->
```text
$ git log --oneline --decorate
849080a (HEAD -> main, tag: v0.1.0) Add serving image definition and model pointer
de800cc Add evaluation config, prompt and run recorder
6a39a54 Version the ticket data set by reference
e9e2df6 Add notebook filter and the error-analysis notebook
af3a06e Add repository checks, shared hook and CI entry point
05a1465 Add package skeleton, lock file and tests
426268a Add ignore rules and attributes before any content
$ git status --short --ignored
!! data/raw/tickets.csv
!! models/embedder.bin
!! runs/
$ git ls-files | wc -l
      24
$ sh ci/check.sh "$(git rev-list --max-parents=0 HEAD)"
checks: 22 file version(s) examined, 0 problem(s)
checks: 24 file version(s) examined, 0 problem(s)
tests: ok
```
<!-- /snippet -->

### What happened internally

- **Step 1.** Two blobs, one tree, one commit. From now on `git add .` cannot pick up a data file, a checkpoint, `.env` or a run directory, because the rules exist before any of those files do.
- **Step 3.** `git config set core.hooksPath hooks` wrote one line into `.git/config`. Git now looks for `pre-commit` in the tracked directory `hooks/` instead of `.git/hooks/`. The setting is local to this clone.
- **Step 4.** Three more lines in `.git/config` define the filter that `.gitattributes` (committed in step 1) names. On `git add`, Git piped the notebook through `python3 tools/nbstrip.py` and stored the result: the blob has no outputs, the file on disk still has three.
- **Step 5.** `dataref.py add` copied the CSV into `../datastore/sha256/22/...` and wrote `data/raw/tickets.csv.ref`. Git tracks the pointer and `data/README.md`; rule 17 of `.gitignore` hides the CSV.
- **Step 6.** `run_eval.py` wrote `runs/baseline/run.json` and `metrics.json`. The directory is ignored: a run record belongs in a tracker, and Lab 33.3 uses one.
- **Step 8.** `ci/check.sh` examined every file version added after the first commit, then the whole snapshot of `HEAD`. Both read blobs from Git, so the working copy of the notebook, which has outputs, does not trouble it.

### Checkpoint

```bash
git config list --local | grep -e filter -e hooksPath     # four lines
git check-ignore -v data/raw/tickets.csv models/embedder.bin runs/baseline/run.json
python3 tools/dataref.py verify                           # two lines starting with "ok"
git grep -c "sk-demo" HEAD -- notebooks                   # no output, exit status 1
```

The last command is the one that matters: the notebook on disk contains a printed key, and no commit does.

### Failure scenario

You clone the project onto another machine (here: another directory), skip the README, add a second notebook, and commit.

```bash
# 9. A clone without the per-clone setup
git clone -q . ../docqa-laptop && cd ../docqa-laptop
cp ../kit/notebooks/01-error-analysis.ipynb notebooks/02-prompt-comparison.ipynb
git add notebooks && git commit -q -m "Add prompt comparison notebook"
git grep -c "sk-demo" HEAD -- notebooks
sh ci/check.sh origin/main
```

<!-- snippet: ch28/lab-33-1-ai-project-repo/09-failure -->
```text
# Failure scenario: you clone the project on another machine and skip the README.
$ git clone -q . ../docqa-laptop && cd ../docqa-laptop
$ cp ../kit/notebooks/01-error-analysis.ipynb notebooks/02-prompt-comparison.ipynb
$ git add notebooks && git commit -q -m "Add prompt comparison notebook"
$ git grep -c "sk-demo" HEAD -- notebooks
HEAD:notebooks/02-prompt-comparison.ipynb:1
$ sh ci/check.sh origin/main
1ee0b83 notebooks/02-prompt-comparison.ipynb: notebook has outputs
checks: 1 file version(s) examined, 1 problem(s)
HEAD notebooks/02-prompt-comparison.ipynb: notebook has outputs
checks: 25 file version(s) examined, 1 problem(s)
tests: ok
[exit status: 1]
```
<!-- /snippet -->

No `checks:` line was printed by the commit: this clone has no hook. No filter ran: this clone has no filter. The printed key is in the commit. `ci/check.sh` finds the notebook twice, once in the range and once in the snapshot.

### Recovery

The commit has not been pushed, so it can be replaced. Configure the clone as the README says, re-clean the tracked notebooks, and amend.

```bash
# 10. Set up the clone, then re-clean and amend
git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
git config set filter.nbstrip.smudge cat
git config set filter.nbstrip.required true
git config set core.hooksPath hooks
git add --renormalize notebooks
git status --short
git commit -q --amend --no-edit
```

<!-- snippet: ch28/lab-33-1-ai-project-repo/10-recovery -->
```text
# The commit is not pushed. Configure the clone as the README says, then re-clean and amend:
$ git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
$ git config set filter.nbstrip.smudge cat
$ git config set filter.nbstrip.required true
$ git config set core.hooksPath hooks
$ git add --renormalize notebooks
$ git status --short
M  notebooks/02-prompt-comparison.ipynb
$ git commit -q --amend --no-edit
checks: 1 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

`git add --renormalize` re-ran the clean filter on the tracked notebooks and staged the difference. 🟡 CAUTION: `git commit --amend` replaces the tip commit with a new one; it is appropriate only because nobody else has the old one.

### Verification

```bash
git grep -c "sk-demo" HEAD -- notebooks
sh ci/check.sh origin/main
git grep -c "sk-demo" "HEAD@{1}" -- notebooks
```

<!-- snippet: ch28/lab-33-1-ai-project-repo/11-verify -->
```text
$ git grep -c "sk-demo" HEAD -- notebooks
[exit status: 1]
$ sh ci/check.sh origin/main
checks: 1 file version(s) examined, 0 problem(s)
checks: 25 file version(s) examined, 0 problem(s)
tests: ok
[exit status: 0]
# The first version of the commit is still in this clone, reachable from the reflog:
$ git grep -c "sk-demo" "HEAD@{1}" -- notebooks
HEAD@{1}:notebooks/02-prompt-comparison.ipynb:1
```
<!-- /snippet -->

`HEAD` is clean and the CI script passes. The third command is a warning, not a success: the replaced commit is still in this clone, reachable through the reflog, with the key in it. That is harmless for a commit that never left your machine. Had it been pushed, the key would have to be rotated, whatever you did to the history afterwards.

### Questions

1. Why is the ignore file the first commit and not the last? Describe one concrete mistake that the order prevents in step 5 and one in step 7.
2. Step 4 commits the filter script and the first notebook together. What would be in history if the notebook had been committed one commit earlier?
3. After step 4, `grep -c output_type` on the file prints 3 and on the blob prints 0. Which of the two does `git diff` compare with the index, and what follows for a reviewer?
4. The clone in step 9 had `.gitattributes` with `*.ipynb filter=nbstrip`, and the original clone had `filter.nbstrip.required true`. Why did neither stop the commit?
5. `ci/check.sh` reported the bad notebook twice. Describe a history in which the `--range` check finds a problem and the `--tree` check does not.
6. The recovery worked because the commit was unpushed. List what would be different if it had been pushed to a shared branch on GitHub, in the order you would act.
7. Which of the seven commits would you protect with a CODEOWNERS entry, and why those?

## Lab 33.2: Version a dataset by reference

### Objective

Put a data file under version control without putting its bytes in Git: record it, change it, go back to the old version, and restore it in a fresh clone. Then edit the data without recording the edit, watch a metric change while the commit ID stays the same, and diagnose it from the run records.

### Prerequisites

Chapter 28, sections 28.6 and 28.7. The pointer idea from [Chapter 22](../textbook/ch22-git-lfs.md), section 22.3.

### Setup

```bash
bash labs/ch28/setup-33-2-dataset-by-reference.sh
labs/shell m33-2
cd docqa
```

Starting state: the `docqa` repository with its tooling and evaluation committed. `data/raw/tickets.csv` (ten labelled tickets) is on disk, ignored, and not yet versioned in any way. Read `tools/dataref.py` before you start.

### Commands

```bash
# 1. Where things stand
git status --short --ignored
git check-ignore -v data/raw/tickets.csv
wc -l < data/raw/tickets.csv

# 2. Record version 1 and evaluate on it
python3 tools/dataref.py add data/raw/tickets.csv
cat data/raw/tickets.csv.ref
git add data/raw/tickets.csv.ref
git commit -q -m "Version the ticket data set by reference"
python3 evals/run_eval.py v1

# 3. Two new labelled tickets: version 2
printf '"I need a receipt for last month",billing\n"Sync stopped working after the update",technical\n' >> data/raw/tickets.csv
git status --short
python3 tools/dataref.py verify
python3 tools/dataref.py add data/raw/tickets.csv
git diff --stat
git commit -q -am "Add two labelled tickets to the data set"
python3 evals/run_eval.py v2

# 4. Back to version 1, and forward again
git switch -q --detach HEAD~1
python3 tools/dataref.py checkout
python3 evals/run_eval.py v1-again
cmp runs/v1/metrics.json runs/v1-again/metrics.json && echo same metrics
git switch -q main && python3 tools/dataref.py checkout

# 5. A clone has the pointer, not the data
git clone -q . ../docqa-ravi
ls ../docqa-ravi/data/raw
(cd ../docqa-ravi && python3 tools/dataref.py checkout && python3 tools/dataref.py verify)
```

### Expected output

<!-- snippet: ch28/lab-33-2-dataset-by-reference/01-start -->
```text
$ git status --short --ignored
!! data/raw/
$ git check-ignore -v data/raw/tickets.csv
.gitignore:17:/data/**	data/raw/tickets.csv
$ wc -l < data/raw/tickets.csv
      11
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-2-dataset-by-reference/02-add -->
```text
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:2226b23c455b (432 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ cat data/raw/tickets.csv.ref
{
  "path": "tickets.csv",
  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
  "size": 432
}
$ git add data/raw/tickets.csv.ref
$ git commit -q -m "Version the ticket data set by reference"
checks: 1 file version(s) examined, 0 problem(s)
$ python3 evals/run_eval.py v1
run v1: accuracy 0.8000 on 10 examples (commit a824a38)
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-2-dataset-by-reference/03-new-version -->
```text
$ printf '"I need a receipt for last month",billing\n"Sync stopped working after the update",technical\n' >> data/raw/tickets.csv
$ git status --short
$ python3 tools/dataref.py verify
differs  data/raw/tickets.csv  (pointer sha256:2226b23c455b)
[exit status: 1]
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:fe4179260782 (524 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ git diff --stat
 data/raw/tickets.csv.ref | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git commit -q -am "Add two labelled tickets to the data set"
checks: 1 file version(s) examined, 0 problem(s)
$ python3 evals/run_eval.py v2
run v2: accuracy 0.6667 on 12 examples (commit d624604)
```
<!-- /snippet -->

The accuracy fell from 0.8 to 0.6667. Nothing is wrong: the two new tickets contain no keyword the baseline knows, so the data set became harder. A metric is a statement about code and data together.

<!-- snippet: ch28/lab-33-2-dataset-by-reference/04-back -->
```text
$ git switch -q --detach HEAD~1
$ python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:2226b23c455b
$ python3 evals/run_eval.py v1-again
run v1-again: accuracy 0.8000 on 10 examples (commit a824a38)
$ cmp runs/v1/metrics.json runs/v1-again/metrics.json && echo same metrics
same metrics
$ git switch -q main && python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:fe4179260782
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-2-dataset-by-reference/05-clone -->
```text
$ git clone -q . ../docqa-ravi
$ ls ../docqa-ravi/data/raw
tickets.csv.ref
$ (cd ../docqa-ravi && python3 tools/dataref.py checkout && python3 tools/dataref.py verify)
restored    data/raw/tickets.csv from sha256:fe4179260782
ok       data/raw/tickets.csv  (pointer sha256:fe4179260782)
```
<!-- /snippet -->

### What happened internally

- **Step 2.** `dataref.py add` computed the SHA-256 of the file, copied the file to `../datastore/sha256/<first two characters>/<the rest>`, and wrote the pointer. `git add` staged a blob of a few lines. The object database of the repository contains no ticket text.
- **Step 3.** Appending to the CSV changed no tracked file, so `git status` was empty. `verify` recomputed the hash and compared it with the pointer. The second `add` stored a second object and rewrote the pointer; `git diff --stat` shows two changed lines, the hash and the size.
- **Step 4.** `git switch --detach HEAD~1` put the old pointer into the working tree and left the ignored CSV alone. `dataref.py checkout` then copied the object the pointer names over the CSV. The rerun gave byte-identical metrics.
- **Step 5.** The clone received commits, trees and blobs: the pointer, not the data. `checkout` in the clone read the store, which both directories reach through the relative path `../datastore`.

### Checkpoint

```bash
python3 tools/dataref.py verify                 # ok ... (pointer sha256:fe4179260782)
git log --oneline -- data/raw/tickets.csv.ref   # two commits
find ../datastore -type f | wc -l               # 2
git rev-list --objects --all | grep -c 'tickets.csv$'   # 0: the CSV was never in Git
```

### Failure scenario

Somebody notices a wrong label and corrects it directly in the CSV. Nothing is recorded.

```bash
# 6. An unrecorded edit
sed -i.bak 's/"My card was declined",billing/"My card was declined",general/' data/raw/tickets.csv && rm data/raw/tickets.csv.bak
git status --short
python3 evals/run_eval.py after-edit
grep -h -e "\"commit\"" -e "\"dirty\"" -e accuracy runs/v2/run.json runs/after-edit/run.json

# 7. Diagnose
python3 tools/dataref.py verify
grep -h -A2 "\"data\"" runs/v2/run.json runs/after-edit/run.json | grep sha256
grep sha256 data/raw/tickets.csv.ref
```

<!-- snippet: ch28/lab-33-2-dataset-by-reference/06-failure -->
```text
# Failure scenario: a label is corrected directly in the data file, and nothing is recorded.
$ sed -i.bak 's/"My card was declined",billing/"My card was declined",general/' data/raw/tickets.csv && rm data/raw/tickets.csv.bak
$ git status --short
$ python3 evals/run_eval.py after-edit
run after-edit: accuracy 0.7500 on 12 examples (commit d624604)
$ grep -h -e "\"commit\"" -e "\"dirty\"" -e accuracy runs/v2/run.json runs/after-edit/run.json
    "commit": "d624604cfa4b37bf336a8514687ce04bd484b07d",
    "dirty": false,
    "accuracy": 0.6667,
    "commit": "d624604cfa4b37bf336a8514687ce04bd484b07d",
    "dirty": false,
    "accuracy": 0.75,
```
<!-- /snippet -->

Two runs with the same commit, both with `dirty: false`, and two different accuracies. Git is right on both counts: no tracked file changed.

<!-- snippet: ch28/lab-33-2-dataset-by-reference/07-diagnose -->
```text
$ python3 tools/dataref.py verify
differs  data/raw/tickets.csv  (pointer sha256:fe4179260782)
[exit status: 1]
$ grep -h -A2 "\"data\"" runs/v2/run.json runs/after-edit/run.json | grep sha256
    "sha256": "fe41792607827f54406ec91db466e90dfcbe446d7ea4846d21b17c9a8a4ded50"
    "sha256": "15fa7d516776ecd6f12d96443462102e772df1813b73a24c8fdb272b7d038448"
$ grep sha256 data/raw/tickets.csv.ref
  "sha256": "fe41792607827f54406ec91db466e90dfcbe446d7ea4846d21b17c9a8a4ded50",
```
<!-- /snippet -->

The run record is what saves the diagnosis: `run_eval.py` stores the checksum of the data it read. The first run's checksum equals the pointer; the second run's does not. The data on disk no longer is the data the commit names.

### Recovery

There are two correct recoveries and you must choose. If the edit is unwanted, `python3 tools/dataref.py checkout` restores the recorded version and **overwrites the edit**. Here the correction is wanted, so record it as a new version.

```bash
# 8. Record the correction
python3 tools/dataref.py add data/raw/tickets.csv
git commit -q -am "Relabel the declined-card ticket as general"
```

<!-- snippet: ch28/lab-33-2-dataset-by-reference/08-recovery -->
```text
# The correction is wanted, so record it as a new version (to discard it: dataref.py checkout).
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:15fa7d516776 (524 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ git commit -q -am "Relabel the declined-card ticket as general"
checks: 1 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

### Verification

```bash
python3 tools/dataref.py verify
git log --oneline -- data/raw/tickets.csv.ref
find ../datastore -type f | wc -l
```

<!-- snippet: ch28/lab-33-2-dataset-by-reference/09-verify -->
```text
$ python3 tools/dataref.py verify
ok       data/raw/tickets.csv  (pointer sha256:15fa7d516776)
$ git log --oneline -- data/raw/tickets.csv.ref
d358a28 Relabel the declined-card ticket as general
d624604 Add two labelled tickets to the data set
a824a38 Version the ticket data set by reference
$ find ../datastore -type f | wc -l
       3
```
<!-- /snippet -->

Three versions, three commits that touch the pointer, three objects in the store. Rerun the evaluation now and its record names a commit whose pointer matches the data it read.

### Questions

1. `git status` was empty after you appended two rows to the data file. Is that a defect of Git, of the ignore rule, or of neither? What would you lose by un-ignoring the file?
2. The pointer records a SHA-256 and a size. Which of the two identifies the data, what is the other one good for, and why is a file name or a date not enough?
3. In step 4 you needed two commands to go back one version. Git LFS needs one. Explain the mechanism that makes the difference, and name one failure each design has that the other does not.
4. In the failure scenario both run records say `dirty: false`. Should `runinfo.py` have reported the tree as dirty? Argue from what "dirty" means in Git, then say what you would change in `run_eval.py` instead.
5. What exactly would `python3 tools/dataref.py checkout` have destroyed in step 8, and where could you have recovered it from?
6. The clone in step 5 found the store because it sits at the same relative path. In a team the store is a bucket. List what must be true about that bucket for a commit from two years ago to be reproducible.
7. Translate steps 2 to 5 into DVC commands as Chapter 28 gives them, and say which file in DVC corresponds to `tickets.csv.ref`.

## Lab 33.3: Reproduce a past result from its recorded identifiers

### Objective

A run record names a commit, a data checksum and a configuration. The repository has moved on since. Rebuild the exact state in a second worktree, rerun, and prove that the new record is identical to the old one. Then do the same for a result that was produced from a dirty tree.

### Prerequisites

Chapter 28, section 28.7. `git worktree` from [Chapter 25](../textbook/ch25-worktrees.md), `git apply` and detached HEAD from Chapters 7 and 11, and Lab 33.2.

### Setup

```bash
bash labs/ch28/setup-33-3-reproduce-result.sh
labs/shell m33-3
cd docqa
```

Starting state: `docqa` at release `v0.1.0` plus two later commits (four more labelled tickets, two more keywords). `../tracker/` plays an experiment tracker and holds two recorded runs, `baseline` (accuracy 0.8) and `tuned` (accuracy 0.9), each with `metrics.json` and `run.json`.

### Commands

```bash
# 1. Today's code and data do not give the recorded number
git log --oneline --decorate -4
python3 evals/run_eval.py today
cat ../tracker/baseline/metrics.json

# 2. Read the record
grep -e "\"commit\"" -e "\"dirty\"" -e "\"describe\"" ../tracker/baseline/run.json
grep -A2 "\"data\"" ../tracker/baseline/run.json

# 3. The recorded commit, in a worktree of its own, with the data its pointer names
commit=$(python3 -c "import json; print(json.load(open('../tracker/baseline/run.json'))['code']['commit'])")
git worktree add --detach ../repro "$commit"
cd ../repro
python3 tools/dataref.py checkout
grep sha256 data/raw/tickets.csv.ref

# 4. Rerun and compare the whole record
python3 evals/run_eval.py repro
diff runs/repro/run.json ../tracker/baseline/run.json && echo "identical record"
```

### Expected output

<!-- snippet: ch28/lab-33-3-reproduce-result/01-today -->
```text
$ git log --oneline --decorate -4
babb70d (HEAD -> main) Add slow and sync as technical keywords
bef8975 Add four labelled tickets to the data set
aa18ad2 (tag: v0.1.0) Add serving image definition and model pointer
8a681ec Add evaluation config, prompt and run recorder
$ python3 evals/run_eval.py today
run today: accuracy 0.7857 on 14 examples (commit babb70d)
$ cat ../tracker/baseline/metrics.json
{
  "accuracy": 0.8,
  "examples": 10
}
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-3-reproduce-result/02-read-record -->
```text
$ grep -e "\"commit\"" -e "\"dirty\"" -e "\"describe\"" ../tracker/baseline/run.json
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "describe": "v0.1.0",
    "dirty": false,
$ grep -A2 "\"data\"" ../tracker/baseline/run.json
  "data": {
    "path": "data/raw/tickets.csv",
    "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e"
--
    "data": "data/raw/tickets.csv",
    "default": "general",
    "keywords": {
```
<!-- /snippet -->

<!-- snippet: ch28/lab-33-3-reproduce-result/03-worktree -->
```text
# Check the recorded commit out beside your work, without disturbing it:
$ commit=$(python3 -c "import json; print(json.load(open('../tracker/baseline/run.json'))['code']['commit'])")
$ git worktree add --detach ../repro "$commit"
Preparing worktree (detached HEAD aa18ad2)
HEAD is now at aa18ad2 Add serving image definition and model pointer
$ cd ../repro
$ python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:2226b23c455b
restored    models/embedder.bin from sha256:7daca2095d04
$ grep sha256 data/raw/tickets.csv.ref
  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
```
<!-- /snippet -->

The pointer in the old commit names the checksum the record names. That equality is the link between the Git history and the run.

<!-- snippet: ch28/lab-33-3-reproduce-result/04-rerun -->
```text
$ python3 evals/run_eval.py repro
run repro: accuracy 0.8000 on 10 examples (commit aa18ad2)
$ diff runs/repro/run.json ../tracker/baseline/run.json && echo "identical record"
identical record
```
<!-- /snippet -->

### What happened internally

- **Step 1.** `main` has fourteen tickets and more keywords, so today's accuracy is a statement about a different experiment.
- **Step 3.** `git worktree add --detach` created a second working tree with its own `HEAD` and index, attached to the same object database and the same configuration, so the notebook filter and the hook path apply there too. Your work in `docqa` is untouched. The new worktree has the old pointer and no data; `dataref.py checkout` fetched both objects the old commit names.
- **Step 4.** The record contains no timestamp, host name or path, on purpose: every field is a function of the code, the data, the lock file and the configuration. That is why `diff` can compare whole records, and why an identical record is proof of reproduction and not only a matching number.

### Checkpoint

```bash
git worktree list              # two entries: docqa on main, repro detached at aa18ad2
git -C ../docqa status --short # nothing: the main worktree was not disturbed
python3 tools/dataref.py verify
```

### Failure scenario

The result that everybody quotes is not the baseline. It is `tuned`, accuracy 0.9.

```bash
# 5. The quoted result
cat ../tracker/tuned/metrics.json
grep -e "\"commit\"" -e "\"dirty\"" -e "\"diff_sha256\"" ../tracker/tuned/run.json
cat runs/repro/metrics.json
```

<!-- snippet: ch28/lab-33-3-reproduce-result/05-failure -->
```text
# Failure scenario: the result everybody quotes is "tuned", accuracy 0.9.
$ cat ../tracker/tuned/metrics.json
{
  "accuracy": 0.9,
  "examples": 10
}
$ grep -e "\"commit\"" -e "\"dirty\"" -e "\"diff_sha256\"" ../tracker/tuned/run.json
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "diff_sha256": "71195d1fdbe1681494c2eca7772d5753adaeb9e886818b92607d602d432790e7",
    "dirty": true,
# Same commit as the baseline. Rerunning that commit gives the baseline number, not 0.9:
$ cat runs/repro/metrics.json
{
  "accuracy": 0.8,
  "examples": 10
}
```
<!-- /snippet -->

The record names the same commit as the baseline, and you already know what that commit gives: 0.8. A tracker that showed only the commit would present two runs of the same code with two results. This record has two more fields: `dirty: true`, and the hash of an uncommitted diff.

### Recovery

The run saved the uncommitted change. Apply it to the recorded commit, prove it is the same change, and rerun.

```bash
# 6. Rebuild the dirty state
cat ../tracker/tuned/uncommitted.patch
git apply ../tracker/tuned/uncommitted.patch
git diff HEAD --binary | shasum -a 256
python3 evals/run_eval.py repro-tuned --allow-dirty
```

<!-- snippet: ch28/lab-33-3-reproduce-result/06-recovery -->
```text
# The record says the tree was dirty, and the run saved the uncommitted change:
$ cat ../tracker/tuned/uncommitted.patch
diff --git a/configs/eval.json b/configs/eval.json
index 64030a3..d43fcfd 100644
--- a/configs/eval.json
+++ b/configs/eval.json
@@ -2,7 +2,7 @@
   "data": "data/raw/tickets.csv",
   "default": "general",
   "keywords": {
-    "billing": ["invoice", "refund", "charged"],
+    "billing": ["invoice", "refund", "charged", "card"],
     "technical": ["error", "crash", "timeout"]
   }
 }
$ git apply ../tracker/tuned/uncommitted.patch
$ git diff HEAD --binary | shasum -a 256
71195d1fdbe1681494c2eca7772d5753adaeb9e886818b92607d602d432790e7  -
$ python3 evals/run_eval.py repro-tuned --allow-dirty
run repro-tuned: accuracy 0.9000 on 10 examples (commit aa18ad2, dirty)
```
<!-- /snippet -->

The SHA-256 of your working-tree diff equals `diff_sha256` in the record: the tree you rebuilt differs from the commit in exactly the way the original tree did.

### Verification

```bash
diff runs/repro-tuned/run.json ../tracker/tuned/run.json && echo "identical record"
git switch -q -c experiment/card-keyword
git commit -q -am "Treat card as a billing keyword"
python3 evals/run_eval.py card-keyword
cd ../docqa && git worktree list
```

<!-- snippet: ch28/lab-33-3-reproduce-result/07-verify -->
```text
$ diff runs/repro-tuned/run.json ../tracker/tuned/run.json && echo "identical record"
identical record
# Make the result citable: commit the change, so that one commit ID identifies it.
$ git switch -q -c experiment/card-keyword
$ git commit -q -am "Treat card as a billing keyword"
checks: 1 file version(s) examined, 0 problem(s)
$ python3 evals/run_eval.py card-keyword
run card-keyword: accuracy 0.9000 on 10 examples (commit 63dc7f5)
$ cd ../docqa && git worktree list
$LAB/ch28/lab-33-3-reproduce-result/docqa babb70d [main]
$LAB/ch28/lab-33-3-reproduce-result/repro 63dc7f5 [experiment/card-keyword]
```
<!-- /snippet -->

The record is identical, so the 0.9 is reproduced. The last three commands make it citable: once the change is a commit, one ID identifies the result, with `dirty: false`. When you are done, `git worktree remove ../repro` deletes the second working tree; the branch `experiment/card-keyword` stays.

### Questions

1. `diff` reported the two `run.json` files as identical. List the fields of the record and say, for each, what would have had to differ for the reproduction to fail.
2. Why a worktree and not `git switch --detach` in the main directory? Name what each approach does to uncommitted work, to the ignored data file, and to a long-running job in the main directory.
3. The `tuned` record names the same commit as `baseline`. Suppose the run had not saved `uncommitted.patch` but had saved `diff_sha256`. What could you still prove, and what could you no longer do?
4. `git apply` succeeded. Under what circumstances would the same patch fail to apply, and why can that not happen here?
5. The record does not contain a timestamp. Give one argument for adding one and one for keeping it out of the file that you compare.
6. `runinfo.py` reports untracked files separately from `dirty`. Describe a run that this record could not reproduce even with the patch.
7. After the verification, which identifiers would you write in a model card for the 0.9 result, and which would you refuse to write?

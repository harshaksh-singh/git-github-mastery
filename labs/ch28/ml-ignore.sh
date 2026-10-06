#!/usr/bin/env bash
# Chapter 28, section 28.9: ignore rules for an ML repository. Which rule ignores which path;
# why an ignore rule does nothing for a file that is already tracked; and why removing the file
# from the index does nothing for history.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 ml-ignore
fx_docqa 2
mkdir -p data/raw data/processed models/v1 runs/r1 wandb notebooks/.ipynb_checkpoints checkpoints
: > data/raw/tickets.csv; : > data/raw/tickets.csv.ref; : > data/processed/train.parquet
: > models/v1/model.safetensors; : > checkpoints/epoch-3.ckpt; : > runs/r1/metrics.json
: > wandb/debug.log; : > .env; : > .env.example; : > notebooks/.ipynb_checkpoints/x.ipynb
: > data/README.md

snip 01-which-rule
run 'git check-ignore -v data/raw/tickets.csv data/processed/train.parquet models/v1/model.safetensors checkpoints/epoch-3.ckpt runs/r1/metrics.json wandb/debug.log .env'
note 'The pointer, the README and the example file are not ignored: no output, exit status 1.'
run_rc 'git check-ignore data/raw/tickets.csv.ref data/README.md .env.example'
note 'With -v, Git names the last matching pattern even when it is a negation (it starts with "!"):'
run 'git check-ignore -v data/raw/tickets.csv.ref data/README.md .env.example'

snip 02-status
run 'git status --short'
run 'git status --short --ignored | grep "^!!"'

hidden 'git clean -fdx -e src -e tests'
hidden 'git switch -c before-rules'
snip 03-tracked-before-rule
note 'A checkpoint was committed before anybody wrote a rule for it:'
hidden 'git rm -q --cached .gitignore && git commit -m "Remove ignore file (simulating a project without one)"'
hidden 'rm .gitignore'
python3 -c "import sys; sys.stdout.buffer.write(bytes(range(256)) * 1024)" > classifier.ckpt
run 'git add classifier.ckpt && git commit -q -m "Add trained classifier"'
run "printf '*.ckpt\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore checkpoints'"
run 'git ls-files'
run_rc 'git check-ignore -v classifier.ckpt'
run 'git check-ignore -v --no-index classifier.ckpt'
note 'The rule matches the path, and Git keeps tracking the file: retraining shows up as a change.'
python3 -c "import sys; sys.stdout.buffer.write(bytes(range(255, -1, -1)) * 1024)" > classifier.ckpt
run 'git status --short'

snip 04-untrack
hidden 'git restore classifier.ckpt'
run 'git rm --cached classifier.ckpt'
run 'git commit -q -m "Stop tracking the checkpoint"'
run 'git status --short --ignored'
note 'Untracked from now on. History is unchanged: every clone still downloads the blob.'
run 'git log --oneline -- classifier.ckpt'
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep ckpt"
lab_end

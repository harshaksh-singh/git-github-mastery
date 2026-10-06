#!/usr/bin/env bash
# "git clean": the one everyday command that deletes files Git has no copy of.
# Dry runs first, then -d, -X and -x, and what is left afterwards. Chapter 4, section 4.14.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 clean

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf '.env\n__pycache__/\ndata/\n*.log\n' > .gitignore
quiet 'git add . && git commit -m "Add service skeleton"'

# Untracked, not ignored
printf 'print("quick test")\n' > scratch.py
mkdir -p experiments/run1
printf 'lr: 0.001\n' > experiments/run1/params.yaml
# Untracked and ignored
printf 'LLM_API_KEY=lab-secret-0001\n' > .env
mkdir -p data src/__pycache__
printf '{"id": 1}\n' > data/tickets.jsonl
printf 'bytecode\n' > src/__pycache__/app.cpython-314.pyc
printf 'started\n' > server.log
# An untracked nested repository
git init -q vendor/tokenizer
printf 'vocab\n' > vendor/tokenizer/vocab.txt

snip 01-start
run 'git status --short --ignored'

snip 02-refuses
run_rc 'git clean'

snip 03-dry-runs
note 'Untracked files in the current directory only.'
run 'git clean -n'
note 'Add -d: untracked directories too.'
run 'git clean -n -d'
note 'Add -X: only what the ignore rules match.'
run 'git clean -n -d -X'
note 'Add -x instead: ignore rules are not used at all, so everything untracked goes.'
run 'git clean -n -d -x'

snip 04-exclude
note 'Protect one pattern from a -x run.'
run 'git clean -n -d -x -e .env'

snip 05-clean-fd
run 'git clean -f -d'
run 'git status --short --ignored'

snip 06-clean-fdx
run 'git clean -f -d -x'
run 'git status --short --ignored'
run_rc 'cat .env'
run 'git fsck'
note 'fsck prints nothing: no object ever held those files. Git cannot bring them back.'

snip 07-nested-repository
note 'One -f never deletes a directory that has its own .git. Two do.'
run 'git clean -n -d -f -f'

lab_end

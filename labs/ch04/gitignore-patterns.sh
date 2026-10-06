#!/usr/bin/env bash
# .gitignore pattern syntax, precedence between ignore sources, negation and its limit,
# and "git check-ignore -v" as the debugger. Chapter 4, section 4.5.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 gitignore-patterns

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'model: small-v1\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'

cat > .gitignore <<'IGN'
# caches and logs, at any depth
__pycache__/
*.log

# build output, only at the top level
/build/

# datasets stay out; the README that documents them stays in
data/*
!data/README.md

# secrets, with one documented exception
.env*
!.env.example

# model weights under models/, at any depth
models/**/*.bin
IGN

mkdir -p src/__pycache__ logs build src/build data models/v1/checkpoints
printf 'bytecode\n' > src/__pycache__/app.cpython-314.pyc
printf 'started\n' > logs/app.log
printf 'artifact\n' > build/out.txt
printf 'def helper():\n    return 1\n' > src/build/helper.py
printf '{"id": 1}\n' > data/tickets.jsonl
printf 'Datasets are downloaded by scripts/fetch_data.sh.\n' > data/README.md
printf 'LLM_API_KEY=lab-secret-0001\n' > .env
printf 'LLM_API_KEY=lab-secret-0002\n' > .env.local
printf 'LLM_API_KEY=\n' > .env.example
printf 'weights\n' > models/v1/model.bin
printf 'weights\n' > models/v1/checkpoints/step-100.bin
printf '# Model card\n' > models/v1/card.md

snip 01-file
run 'cat -n .gitignore'

snip 02-check-ignore
note 'Output: <source>:<line>:<pattern> TAB <path>. With -n, a path that matches no pattern prints "::".'
run 'git check-ignore -v -n src/__pycache__/app.cpython-314.pyc logs/app.log build/out.txt src/build/helper.py'
run 'git check-ignore -v -n data/tickets.jsonl data/README.md .env .env.local .env.example'
run 'git check-ignore -v -n models/v1/model.bin models/v1/checkpoints/step-100.bin models/v1/card.md'

snip 03-status
run 'git status --short --untracked-files=all'

snip 04-negation-limit
note 'Edit line 10 from "data/*" to "data/": the directory itself is now excluded.'
sed -e 's|^data/\*$|data/|' .gitignore > .gitignore.new && mv .gitignore.new .gitignore
run "grep -n 'data' .gitignore"
run 'git check-ignore -v data/README.md'
run 'git status --short --untracked-files=all data'
sed -e 's|^data/$|data/*|' .gitignore > .gitignore.new && mv .gitignore.new .gitignore

snip 05-nested
note 'A .gitignore in a subdirectory overrides the ones above it, for paths below it.'
mkdir -p experiments/run1
printf 'epoch 1 loss 0.91\n' > experiments/run1/train.log
run "printf '!*.log\n' > experiments/.gitignore"
run 'git check-ignore -v -n experiments/run1/train.log logs/app.log'

snip 06-personal
note 'Patterns for this clone only, never committed: .git/info/exclude'
run "printf 'scratch/\n' >> .git/info/exclude"
mkdir -p scratch notebooks
printf 'print("try")\n' > scratch/try.py
note 'Patterns for every repository on this machine: the file named by core.excludesFile.'
note 'Its default is $XDG_CONFIG_HOME/git/ignore, or ~/.config/git/ignore when that variable is unset.'
run 'mkdir -p "$XDG_CONFIG_HOME/git"'
run "printf '.DS_Store\n.idea/\n*.ipynb\n' > \"\$XDG_CONFIG_HOME/git/ignore\""
printf 'binary\n' > .DS_Store
printf '{}\n' > notebooks/scratch.ipynb
printf '{}\n' > notebooks/report.ipynb
run 'git check-ignore -v scratch/try.py .DS_Store notebooks/scratch.ipynb'

snip 07-precedence
note 'The repository wants one notebook tracked. A per-directory .gitignore outranks the personal files.'
run "printf '\n!notebooks/report.ipynb\n' >> .gitignore"
run 'git check-ignore -v -n notebooks/report.ipynb notebooks/scratch.ipynb'
run 'git status --short --untracked-files=all notebooks'

snip 08-force
note 'Ignore rules are advice for untracked paths. "git add -f" overrides them for one path.'
run_rc 'git add models/v1/model.bin'
run 'git add -f models/v1/model.bin'
run 'git status --short models'

lab_end

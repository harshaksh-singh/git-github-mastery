#!/usr/bin/env bash
# "git commit -a" and "git commit <path>": two ways to commit that bypass what you staged.
# Chapter 5, section 5.10.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 commit-shortcuts

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config docs
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'TOP_K = 5\n' > src/retriever.py
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
printf 'Old design notes.\n' > docs/old-notes.md
quiet 'git add . && git commit -m "Add service skeleton"'

snip 01-commit-a
printf 'TOP_K = 8\n' > src/retriever.py
rm docs/old-notes.md
printf 'SYSTEM = "You are a support assistant."\n' > src/prompts.py
note 'One modified file, one deleted file, one new file. Nothing staged.'
run 'git status --short'
run 'git commit -a -m "Raise TOP_K and drop old notes"'
run 'git status --short'
note '-a staged the modification and the deletion. The new file is still untracked.'

snip 02-commit-path
printf 'temperature: 0.2\n' >> config/settings.yaml
git add config/settings.yaml
printf 'TOP_K = 10\n' > src/retriever.py
note 'settings.yaml is staged. retriever.py is modified and not staged.'
run 'git status --short'
run 'git commit src/retriever.py -m "Raise TOP_K to 10"'
run 'git show --stat --format=%s HEAD'
run 'git status --short'
note 'The commit took retriever.py from the working tree and left the staged settings.yaml for later.'

snip 03-commit-path-overrides-partial-staging
note 'Stage a clean version of retriever.py while the working tree also holds a debug line.'
printf 'TOP_K = 12\n' > src/retriever.py
git add src/retriever.py
printf 'TOP_K = 12\nprint("DEBUG TOP_K", TOP_K)\n' > src/retriever.py
run 'git diff --cached -- src/retriever.py'
run 'git diff -- src/retriever.py'
run 'git commit src/retriever.py -m "Raise TOP_K to 12"'
run 'git show HEAD:src/retriever.py'

snip 04-include
printf 'TOP_K = 14\n' > src/retriever.py
note 'settings.yaml is still staged. -i adds the named path on top of what is staged.'
run 'git status --short'
run 'git commit -i src/retriever.py -m "Tune retrieval and sampling"'
run 'git show --stat --format=%s HEAD'

snip 05-untracked-path
run_rc 'git commit src/prompts.py -m "Add prompts"'

snip 06-dry-run
printf 'TOP_K = 16\n' > src/retriever.py
note 'Preview what a commit command would record without creating the commit.'
run 'git commit --dry-run --short -a'
run 'git status --short'

lab_end

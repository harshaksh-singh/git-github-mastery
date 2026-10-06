#!/usr/bin/env bash
# "git update-index --assume-unchanged" and "--skip-worktree": what the two bits do, why
# neither is a way to ignore changes to a tracked file, and the arrangement that is.
# Chapter 5, section 5.12.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch05 assume-skip

git init -q support-bot
cd support-bot || exit 1
mkdir -p src config
printf 'def answer(question):\n    return "ok"\n' > src/app.py
printf 'model: small-v1\napi_base: https://llm.internal.example\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add service skeleton"'
# A teammate changes the same file on another branch.
git switch -q -c teammate
printf 'model: small-v2\napi_base: https://llm.internal.example\n' > config/settings.yaml
quiet 'git commit -am "Switch to small-v2"'
git switch -q main

snip 01-assume-unchanged
run 'git update-index --assume-unchanged config/settings.yaml'
note 'ls-files -v shows the bit as a lower-case tag.'
run 'git ls-files -v'
note 'Point the service at a local model server. A private edit you do not want to commit.'
sed -e 's|https://llm.internal.example|http://localhost:8080|' config/settings.yaml > t && mv t config/settings.yaml
run 'cat config/settings.yaml'
run 'git status --short'
run 'git diff'

snip 02-assume-unchanged-hides-from-everything
note 'It is hidden from every command that asks "what changed?", including the ones you want.'
run 'git add config/settings.yaml'
run 'git status --short'
run 'git stash'

snip 03-assume-unchanged-breaks
note 'The teammate changed the same file. Git checks the real file before overwriting it.'
run_rc 'git merge teammate'
run 'git status'
note 'A clean status and a refused merge at the same time. And restore silently discards the edit:'
run 'git restore config/settings.yaml'
run 'cat config/settings.yaml'
run 'git update-index --no-assume-unchanged config/settings.yaml'

snip 04-skip-worktree
run 'git update-index --skip-worktree config/settings.yaml'
run 'git ls-files -v'
sed -e 's|https://llm.internal.example|http://localhost:8080|' config/settings.yaml > t && mv t config/settings.yaml
note 'The same private edit again.'
run 'git status --short'
run_rc 'git add config/settings.yaml'

snip 05-skip-worktree-breaks
run_rc 'git merge teammate'
run_rc 'git restore config/settings.yaml'
run 'git status --short'

snip 06-find-and-clear
note 'Find paths that carry either bit, then clear them.'
run "git ls-files -v | grep -e '^[a-z]' -e '^S'"
run 'git update-index --no-skip-worktree config/settings.yaml'
run 'git status --short'
quiet 'git restore config/settings.yaml'

snip 07-the-arrangement-that-works
note 'Keep the shared defaults tracked. Put private overrides in a file that no commit has ever tracked.'
run "echo 'config/settings.local.yaml' >> .gitignore"
run 'git add .gitignore'
run 'git commit -m "Ignore the per-developer settings override"'
run "echo 'api_base: http://localhost:8080' > config/settings.local.yaml"
run 'git status --short --ignored'
note 'The teammate change to the tracked defaults now merges, and the private file is untouched.'
run 'git merge teammate'
run 'cat config/settings.yaml config/settings.local.yaml'

lab_end

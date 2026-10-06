#!/usr/bin/env bash
# Exercises of Module 4 (refs, branches, HEAD; Chapter 7): the model runs behind
# exercises/m01-m05-foundations.md and solutions/exercises-m01-m05.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 4.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m04

# ---- Exercise 4.1 (Level 1): create, list, rename, delete, and the file behind each step
snip e01-branch
run 'git init -q model-router'
run 'cd model-router'
run "printf 'routes:\n  default: small\n' > routes.yaml"
run 'git add routes.yaml'
run 'git commit -q -m "Add default route"'
run 'git branch feature/fallback'
run 'git branch -v'
run 'cat .git/refs/heads/feature/fallback'
run 'git rev-parse main'
run 'git branch -m feature/fallback feature/fallback-route'
run 'find .git/refs/heads -type f | sort'
run 'git branch -d feature/fallback-route'
run 'find .git/refs/heads -type f | sort'

# ---- Exercise 4.2 (Level 1): HEAD follows you
snip e02-head
run 'cat .git/HEAD'
run 'git switch -c fix/timeout'
run 'cat .git/HEAD'
run "printf 'routes:\n  default: small\ntimeout_s: 30\n' > routes.yaml"
run 'git commit -q -am "Add request timeout"'
run 'git branch -v'
run 'git switch -'
run 'git symbolic-ref HEAD'
run "git rev-parse --abbrev-ref HEAD '@{-1}'"
run 'git branch -v'

# ---- Exercise 4.3 (Level 1): a lightweight tag is a ref that does not move
snip e03-tag
run 'git tag v0.1.0'
run 'cat .git/refs/tags/v0.1.0'
run "printf '# model-router\n' > README.md"
run 'git add README.md'
run 'git commit -q -m "Add README"'
run 'git rev-parse v0.1.0 main'
run 'git log --oneline --decorate --all'
run 'git cat-file -t v0.1.0'
cd "$LAB_DIR"

# ---- Exercise 4.4 (Level 2, draw the graph): a commit made in detached HEAD
snip e04-setup
run 'git init -q detached'
run 'cd detached'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git commit -q --allow-empty -m C'
run 'git switch -q --detach HEAD~1'
run 'git commit -q --allow-empty -m X'
run 'git switch main'
snip e04-answer
run 'git log --graph --oneline --all'
run 'git reflog -3'
snip e04-keep
run "git branch keep/x 'HEAD@{1}'"
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

# ---- Exercise 4.5 (Level 2, prediction): which branches may be deleted?
snip e05-setup
run 'git init -q cleanup'
run 'cd cleanup'
run 'git commit -q --allow-empty -m A'
run 'git branch done-1'
run 'git switch -q -c done-2'
run 'git commit -q --allow-empty -m D2'
run 'git switch -q main'
run 'git merge -q done-2'
run 'git switch -q -c open-1'
run 'git commit -q --allow-empty -m O1'
run 'git switch -q main'
run 'git commit -q --allow-empty -m B'
snip e05-answer
run 'git branch --merged main'
run 'git branch --no-merged main'
run_rc 'git branch -d done-1 done-2 open-1'
run 'git branch'
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

# ---- Exercise 4.6 (Level 2, draw the graph): from which branch was it created?
snip e06-setup
run 'git init -q lineage'
run 'cd lineage'
run 'git commit -q --allow-empty -m A'
run 'git commit -q --allow-empty -m B'
run 'git switch -q -c feature/a'
run 'git commit -q --allow-empty -m C'
run 'git switch -q -c feature/b'
run 'git commit -q --allow-empty -m D'
run 'git switch -q main'
run 'git commit -q --allow-empty -m E'
run 'git branch feature/c feature/a'
snip e06-answer
run 'git log --graph --oneline --all'
snip e06-lineage
run 'git show -s --format=%s "$(git merge-base feature/b main)"'
run 'git show -s --format=%s "$(git merge-base feature/b feature/a)"'
run 'git reflog show feature/b'
run 'git reflog show feature/c'
run 'git config list --local | grep branch'
cd "$LAB_DIR"

# ---- Exercise 4.7 (Level 3): one switch carries the edit, the next one refuses
snip e07-setup
run 'git init -q carry'
run 'cd carry'
run "printf 'timeout_s: 30\n' > router.yaml"
run "printf 'model: small\n' > model.yaml"
run 'git add .'
run 'git commit -q -m "Add configs"'
run 'git switch -q -c exp/large-model'
run "printf 'model: large\n' > model.yaml"
run 'git commit -q -am "Try the large model"'
run 'git switch -q main'
snip e07-observed
run "printf 'timeout_s: 60\n' > router.yaml"
run 'git switch exp/large-model'
run 'git switch main'
run 'git restore router.yaml'
run "printf 'model: medium\n' > model.yaml"
run_rc 'git switch exp/large-model'
snip e07-explain
run 'git diff --name-only main exp/large-model'
run 'git status --short'
note 'Lowest risk: take the edit to a new branch that starts at the commit you are on.'
run 'git switch -c exp/medium-model'
run 'git commit -q -am "Try the medium model"'
run 'git log --graph --oneline --all'
cd "$LAB_DIR"

# ---- Exercise 4.8 (Level 3): the deploy script that resolves the wrong commit
quiet 'git init deploys'
cd deploys
quiet "printf 'version: 1.0\n' > service.yaml && git add . && git commit -m 'Release 1.0'"
quiet 'git tag release-1.0'
quiet 'git switch -c release-1.0'
quiet "printf 'version: 1.0\nhotfix: clamp-temperature\n' > service.yaml && git commit -am 'Hotfix: clamp temperature'"
quiet 'git switch main'
quiet "printf 'version: 1.1-dev\n' > service.yaml && git commit -am 'Start 1.1'"
snip e08-evidence
run 'git branch -v'
run 'git rev-parse --short release-1.0'
run 'git log --oneline -1 release-1.0'
snip e08-diagnosis
run "git for-each-ref --format='%(refname) %(objectname:short) %(subject)'"
run 'git rev-parse refs/heads/release-1.0 refs/tags/release-1.0'
run 'git rev-parse --short heads/release-1.0'
snip e08-fix
run 'git tag v1.0.0 refs/tags/release-1.0'
run 'git tag -d release-1.0'
run 'git rev-parse --short release-1.0'
run "git for-each-ref --format='%(refname) %(objectname:short) %(subject)'"
cd "$LAB_DIR"

lab_end

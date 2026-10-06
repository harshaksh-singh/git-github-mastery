#!/usr/bin/env bash
# Exercises of Module 7 (remotes; Chapter 12): the model runs behind
# exercises/m06-m10-integration.md and solutions/exercises-m06-m10.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 7.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m07

# ---- Exercise 7.1 (Level 1): what a clone writes down about its remote
mkdir -p "$LAB_DIR/m07-ex1" && cd "$LAB_DIR/m07-ex1"
snip e01-clone
run 'git init -q --bare server.git'
run 'git clone server.git you'
run 'cd you'
run "printf 'TTL_SECONDS = 3600\n' > cache.py"
run 'git add cache.py'
run 'git commit -q -m "Add embedding cache settings"'
run 'git push -u origin main'
snip e01-config
run 'cat .git/config'
run 'git remote -v'
run 'git branch -vv'
run 'git for-each-ref'

# ---- Exercise 7.2 (Level 1): fetch first, look, then integrate
snip e02-teammate
run 'cd ..'
run 'git clone -q server.git asha'
run 'git -C asha commit -q --allow-empty -m "Asha: add eviction policy"'
run 'git -C asha push -q'
run 'cd you'
snip e02-fetch
run 'git status -sb'
run 'git fetch'
run 'git status -sb'
run 'git log --oneline main..origin/main'
run 'git merge --ff-only origin/main'
run 'git status -sb'

# ---- Exercise 7.3 (Level 1): publish a branch, then delete it on the server
snip e03-publish
run 'git switch -q -c feature/ttl'
run 'git commit -q --allow-empty -m "Make the TTL configurable"'
run 'git push -u origin feature/ttl'
run 'git config get branch.feature/ttl.remote'
run 'git config get branch.feature/ttl.merge'
run 'git branch -vv'
snip e03-delete
run 'git push origin --delete feature/ttl'
run 'git branch -r'
run 'git branch -vv'
run 'git ls-remote --heads origin'

# ---- Exercise 7.4 (Level 2, prediction): what the clone knows before and after a fetch
mkdir -p "$LAB_DIR/m07-ex4" && cd "$LAB_DIR/m07-ex4"
snip e04-setup
run 'git init -q --bare server.git'
run 'git clone -q server.git you 2>/dev/null'
run 'git -C you remote set-url origin ../server.git'
run 'git -C you commit -q --allow-empty -m A'
run 'git -C you push -q -u origin main'
run 'git clone -q server.git asha'
run 'git -C asha commit -q --allow-empty -m "Asha: B"'
run 'git -C asha push -q'
run 'cd you'
run 'git commit -q --allow-empty -m "You: C"'
snip e04-answer-before
run 'git status -sb'
run_rc 'git push'
snip e04-answer-after
run 'git fetch -q'
run 'git status -sb'
run_rc 'git push'

# ---- Exercise 7.5 (Level 2, draw the graph): the same pull, by merge and by rebase
snip e05-setup
run 'cd ..'
run 'cp -R you you-rebase'
run 'git -C you pull --no-rebase -q'
run 'git -C you-rebase pull --rebase -q'
snip e05-answer
run 'git -C you log --graph --oneline'
run 'git -C you-rebase log --graph --oneline'
run 'git -C you status -sb'
run 'git -C you-rebase status -sb'

# ---- Exercise 7.6 (Level 2, prediction): which refs does a fetch move?
mkdir -p "$LAB_DIR/m07-ex6" && cd "$LAB_DIR/m07-ex6"
quiet 'git init -q --bare server.git'
quiet 'git clone -q server.git asha'
cd asha
quiet 'git commit -q --allow-empty -m A && git push -q -u origin main'
quiet 'git switch -q -c feature/a && git commit -q --allow-empty -m "Feature a" && git push -q -u origin feature/a'
quiet 'git switch -q -c feature/b main && git commit -q --allow-empty -m "Feature b" && git push -q -u origin feature/b'
cd ..
quiet 'git clone -q server.git you'
cd asha
quiet 'git switch -q main && git commit -q --allow-empty -m B && git push -q'
quiet 'git push -q origin --delete feature/a'
quiet 'git switch -q -c feature/c main && git commit -q --allow-empty -m "Feature c" && git push -q -u origin feature/c'
quiet 'git tag v1.0 main && git push -q origin v1.0'
quiet 'git switch -q feature/b && git commit -q --amend --allow-empty -m "Feature b, reworded" && git push -q --force-with-lease'
cd ../you
snip e06-before
run 'git branch -r'
run 'git ls-remote origin'
snip e06-answer
run 'git fetch'
run 'git branch -r'
run 'git tag'
snip e06-prune
run 'git fetch --prune'
run 'git branch -r'

# ---- Exercise 7.7 (Level 3): the branch that the clone cannot see
mkdir -p "$LAB_DIR/m07-ex7" && cd "$LAB_DIR/m07-ex7"
quiet 'git init --bare server.git'
quiet 'git clone server.git asha'
cd asha
quiet 'git commit --allow-empty -m "Add cache" && git push -u origin main'
quiet 'git switch -c feature/eviction && git commit --allow-empty -m "Add LRU eviction" && git push -u origin feature/eviction'
cd ..
quiet 'git clone --single-branch server.git ci-checkout'
cd ci-checkout
snip e07-evidence
run 'git branch -r'
run 'git fetch'
run_rc 'git switch feature/eviction'
run 'git ls-remote --heads origin'
snip e07-diagnosis
run 'git config get --all remote.origin.fetch'
snip e07-fix
run "git remote set-branches origin '*'"
run 'git config get --all remote.origin.fetch'
run 'git fetch'
run 'git switch feature/eviction'

# ---- Exercise 7.8 (Level 3): a push that the other side refuses
mkdir -p "$LAB_DIR/m07-ex8" && cd "$LAB_DIR/m07-ex8"
quiet 'git init staging-box'
quiet 'git -C staging-box commit --allow-empty -m "Deploy 1"'
quiet 'git clone staging-box ravi'
cd ravi
quiet 'git commit --allow-empty -m "Deploy 2"'
snip e08-evidence
run 'git remote -v'
run_rc 'git push origin main'
snip e08-diagnosis
run 'git -C ../staging-box rev-parse --is-bare-repository'
run 'git -C ../staging-box branch --show-current'
run_rc 'git -C ../staging-box config get receive.denyCurrentBranch'
note 'A branch that is not checked out there is accepted:'
run 'git push origin main:refs/heads/incoming/deploy-2'

lab_end

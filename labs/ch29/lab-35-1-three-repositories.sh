#!/usr/bin/env bash
# Lab 35.1 replay: the ten-command diagnosis on three prepared repositories. For each one: the
# symptom card, the eleven lines, then the commands that test the hypotheses. Failure scenario:
# a state-changing command typed before the diagnosis (leaving a detached HEAD that holds
# commits). Recovery: anchor the commits from the ID Git printed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch29 lab-35-1-three-repositories
fx_35_1
atip=$(git -C annotator rev-parse --short HEAD)

# ------------------------------------------------------------ annotator
snip 01-a-symptom
run 'cat annotator.SYMPTOM.txt'
run 'cd annotator'

snip 02-a-state
run 'git status'
run 'git branch -vv'
run 'git remote -v'
run 'git log --graph --decorate --oneline --all'
run 'git reflog'

snip 03-a-details
run 'git rev-parse HEAD main'
run 'git rev-parse --abbrev-ref HEAD'
run 'git show --stat HEAD'
run 'git diff'
run 'git diff --cached'
run 'git config list --show-scope | grep -E "user[.]|remote[.]|branch[.]"'
run 'git ls-files'

snip 04-a-test
run 'git log --oneline main..HEAD'
run 'git branch -a --contains HEAD'
run 'git stash list'
run 'git stash show -p stash@{0}'

# ------------------------------------------------------------ batch-infer
snip 05-b-symptom
run 'cd ..'
run 'cat batch-infer.SYMPTOM.txt'
run 'cd batch-infer'

snip 06-b-state
run 'git status'
run 'git branch -vv'
run 'git remote -v'
run 'git log --graph --decorate --oneline --all'
run 'git reflog'

snip 07-b-details
run 'git rev-parse HEAD origin/main'
run 'git show --stat HEAD'
run 'git diff'
run 'git diff --cached'
run 'git ls-files'

snip 08-b-test
note 'What does the server have now? Two questions that change nothing locally, then a fetch,'
note 'which moves only remote-tracking refs.'
run 'git ls-remote origin main'
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --left-right HEAD...origin/main'
note 'Why is an ignored file reported as modified?'
run 'cat .gitignore'
run 'git ls-files .env'
run_rc 'git check-ignore -v .env'
run 'git check-ignore -v --no-index .env'
run 'git log --oneline -- .env'

# ------------------------------------------------------------ prompt-router
snip 09-c-symptom
run 'cd ..'
run 'cat prompt-router.SYMPTOM.txt'
run 'cd prompt-router'

snip 10-c-state
run 'git status'
run 'git branch -vv'
run 'git remote -v'
run 'git log --graph --decorate --oneline --all'
run 'git reflog'

snip 11-c-details
run 'git rev-parse HEAD origin/feature/router-cache'
run 'git show --stat HEAD'
run 'git diff'
run 'git diff --cached'
run 'git config list --show-origin --show-scope | grep -E "user[.]"'
run 'git ls-files'
run 'ls router'

snip 12-c-test
run 'git status --ignored'
run 'git check-ignore -v router/cache_keys.py'
run 'git ls-tree -r --name-only origin/feature/router-cache'
run 'git config get --show-origin --show-scope --all user.email'
run "git log -1 --format='%an <%ae>'"

# ------------------------------------------------------------ failure and recovery
snip 13-failure
run 'cd ../annotator'
note 'The reflex: "let me go back to main and look".'
run 'git switch main'
run 'git log --graph --decorate --oneline --all'
run "git branch -a --contains $atip"

snip 14-recovery
run 'git reflog -3'
run "git branch feature/agreement 'HEAD@{1}'"
run 'git log --graph --decorate --oneline --all'

snip 15-verification
run 'git branch --contains feature/agreement'
run 'git log --oneline main..feature/agreement'
run 'git fsck --no-reflogs'

lab_end

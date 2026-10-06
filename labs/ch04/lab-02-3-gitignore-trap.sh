#!/usr/bin/env bash
# Replay of Lab 2.3: the .gitignore trap and its fix. A secret file and a cache directory are
# committed by the first "git add .", an ignore rule is added too late, and the fix is made
# with "git rm --cached". The failure scenario shows what the fix does to a teammate.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/m02-setups.inc"
lab_begin ch04 lab-02-3-gitignore-trap
m02_3_setup || exit 1
cd support-bot || exit 1

snip 01-the-mistake
run 'git init'
run 'git add .'
run 'git commit -m "Add service skeleton"'
run 'git ls-files'

snip 02-rule-added-too-late
run "printf '.env\n__pycache__/\n' > .gitignore"
run 'git add .gitignore'
run 'git commit -m "Add ignore rules"'
note 'A teammate clones at this point.'
run 'git clone -q . ../asha-clone'
run "echo 'LLM_API_KEY=lab-secret-0002' > .env"
run 'git status --short'

snip 03-diagnose
run_rc 'git check-ignore -v .env'
run_rc 'git check-ignore -v --no-index .env'
run 'git ls-files --cached --ignored --exclude-standard'

snip 04-fix
run 'git rm --cached .env'
run 'git rm -r --cached src/__pycache__'
run 'git status --short --ignored'
run 'git commit -m "Stop tracking the environment file and bytecode caches"'

snip 05-checkpoint
run 'git ls-files'
run 'cat .env'
run "echo 'LLM_API_KEY=lab-secret-0003' > .env"
run 'git status --short'
run 'git check-ignore -v .env src/__pycache__/app.cpython-314.pyc'

snip 06-failure
note 'Failure scenario: the teammate pulls your fix.'
run 'cd ../asha-clone'
run 'ls -A . src'
run 'git pull'
run 'ls -A . src'

snip 07-recovery
note 'The file was tracked one commit ago, so that commit still has its content.'
run 'git restore --source=HEAD~1 .env'
run 'cat .env'
run 'git status --short --ignored'

snip 08-verification
run 'git ls-files'
run 'git ls-files --cached --ignored --exclude-standard'
run 'git status'
note 'One thing the fix did not do: the secret is still in history, in every clone.'
run 'git log --oneline -- .env'
run 'git show HEAD~2:.env'

lab_end

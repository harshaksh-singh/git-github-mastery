#!/usr/bin/env bash
# The already-tracked trap: an ignore rule does nothing for a path that is in the index.
# Diagnosis with check-ignore and ls-files, the fix with "git rm --cached", and the two
# things the fix does not do. Chapter 4, section 4.6.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 ignore-tracked-trap

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
printf 'import os\n\nKEY = os.environ["LLM_API_KEY"]\n' > src/app.py
printf 'LLM_API_KEY=lab-secret-0001\n' > .env

snip 01-the-mistake
note 'The first commit is made with "git add ." before any .gitignore exists.'
run 'git add .'
run 'git commit -m "Add service skeleton"'
run 'git ls-files'

snip 02-ignore-does-nothing
run "echo '.env' > .gitignore"
run 'git add .gitignore'
run 'git commit -m "Ignore local environment file"'
# A teammate clones now, while .env is still tracked, and a release branch is cut here.
git clone -q "$PWD" ../asha-clone
git branch release-1.0
run "echo 'LLM_API_KEY=lab-secret-0002' > .env"
run 'git status --short'

snip 03-diagnose
note 'check-ignore reports nothing for a tracked path: ignore rules are not consulted for it.'
run_rc 'git check-ignore -v .env'
note 'Ask the same question with the index left out of it.'
run_rc 'git check-ignore -v --no-index .env'
note 'List every path that is tracked and also matches an ignore pattern.'
run 'git ls-files --cached --ignored --exclude-standard'

snip 04-fix
run 'git rm --cached .env'
run 'git status --short --ignored'
run 'git commit -m "Stop tracking .env"'
run 'git ls-files'
run 'cat .env'

snip 05-now-ignored
run "echo 'LLM_API_KEY=lab-secret-0003' > .env"
run 'git status --short'
run_rc 'git check-ignore -v .env'

snip 06-history-still-has-it
note 'The fix changed the index and the new commit. It did not change any earlier commit.'
run 'git log --oneline -- .env'
run 'git show HEAD~1:.env'

snip 07-teammate
note 'Asha cloned while .env was still tracked. Her local runs read that file.'
run 'cd ../asha-clone'
run 'ls -A'
run 'git pull'
run 'ls -A'
note 'The content is still in the previous commit, so she can get her file back as an ignored file.'
run 'git restore --source=HEAD~1 .env'
run 'git status --short --ignored'

snip 08-ignored-is-expendable
note 'Back in your clone. Your .env is ignored now and holds a value that exists nowhere else.'
run 'cd ../support-bot'
run 'cat .env'
note 'release-1.0 was cut while .env was still tracked.'
run 'git switch release-1.0'
run 'cat .env'
run 'git switch main'
run_rc 'cat .env'

snip 09-no-overwrite-ignore
run "echo 'LLM_API_KEY=lab-secret-0004' > .env"
run_rc 'git switch --no-overwrite-ignore release-1.0'
run 'cat .env'

lab_end

#!/usr/bin/env bash
# Lab 31.1 replay: the secret-leak tabletop. A dummy key was committed, three more commits
# followed, everything was pushed, and two teammates have clones. The response runs through
# contain, assess, eradicate, recover, communicate and prevent. The history rewrite uses
# git filter-branch only because it ships with Git; on a real repository use git-filter-repo.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b lab-31-1-tabletop
fx_ragdesk

snip 01-confirm
run 'ls'
run 'cd ragdesk'
run 'git grep -n LLM_API_KEY -- .env'
run "git log --oneline -S'DUMMY-KEY-not-a-real-secret-12345'"
run 'git status -sb'

snip 02-contain
run '../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345'
run '../provider/keyctl revoke DUMMY-KEY-not-a-real-secret-12345'
run '../provider/keyctl issue'
run '../provider/keyctl status DUMMY-KEY-not-a-real-secret-12345'

snip 03-assess
run 'first=$(git log --format=%h --diff-filter=A -- .env); echo $first'
run "git log -1 --format='%h%nauthor:    %an <%ae>%ncommitted: %cd%nsubject:   %s' --date=iso-local \$first"
run 'git branch -a --contains $first'
run 'git tag --contains $first'
run 'git rev-list --count $first..origin/main'
run "git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' \$(git rev-list --all) | sort | uniq -c"
run 'git reflog show origin/main'

snip 04-eradicate-tip
run 'git rm -q --cached .env'
run "printf '.env\n' > .gitignore"
run "printf 'LLM_API_KEY=\nLLM_BASE_URL=https://llm.example.com\n' > .env.example"
run "git add .gitignore .env.example && git commit -q -m 'Stop tracking .env; add .env.example'"
run 'git push -q origin main'
run 'git grep -c DUMMY-KEY origin/main || echo "tip is clean"'
run 'git grep -c DUMMY-KEY v0.2.0'

snip 05-rewrite
run 'cd ..'
run 'git clone -q --mirror server.git cleanup.git'
run 'cd cleanup.git'
run 'git for-each-ref --format="%(objectname) %(refname)" > ../refs-before.txt'
run "FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter 'git rm --cached --ignore-unmatch -q .env' --tag-name-filter cat -- --all > ../filter.log 2>&1"
run "grep -v 'seconds passed' ../filter.log"

snip 06-verify-rewrite
run "git grep -l DUMMY-KEY \$(git rev-list --all) | wc -l"
run 'git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin'
run "git grep -l DUMMY-KEY \$(git rev-list --all) | wc -l"
run 'git reflog expire --expire=now --all && git gc -q --prune=now'
run_rc 'git cat-file -t $first'
run 'git for-each-ref --format="%(objectname) %(refname)" > ../refs-after.txt'
run "join -1 2 -2 2 ../refs-before.txt ../refs-after.txt | awk '{printf \"%-28s %.7s -> %.7s\\n\", \$1, \$2, \$3}'"

snip 07-force-push
run 'git push --force --mirror origin 2>&1'

snip 08-server-prune
note 'The force push moved the refs. The old commits are still in the server repository:'
run 'git -C ../server.git show $first:.env'
note 'On your own server you can prune. On GitHub only GitHub Support can (section 21B.19).'
run 'git -C ../server.git gc -q --prune=now'
run_rc 'git -C ../server.git cat-file -t $first'

snip 09-recover-own-clone
run 'cd ..'
run 'rm -rf ragdesk'
run 'git clone -q server.git ragdesk'
run 'git -C ragdesk log --oneline'
run 'git -C ragdesk tag -l'
run '(cd ragdesk && git grep -l DUMMY-KEY $(git rev-list --all) | wc -l)'

snip 10-prevent
run 'cp kit/pre-receive server.git/hooks/pre-receive'
run 'cp kit/pre-commit ragdesk/.git/hooks/pre-commit'
note 'Test the server guard with a clone that still has the old history: Ravi pulls and pushes.'
run 'cd ravi'
run 'git pull -q --no-rebase 2>&1'
run 'git log --oneline --graph -4'
run_rc 'git push 2>&1'

snip 11-clean-a-clone-without-local-work
run 'git reset -q --hard origin/main'
run 'git tag -l | xargs git tag -d'
run 'git fetch -q --prune --tags'
run 'git reflog expire --expire=now --all && git gc -q --prune=now'
run_rc 'git cat-file -t $first'
run 'git status -sb'
run 'cd ..'

snip 12-failure
note 'The state of a team that stopped before prevention: no guard on the server.'
run 'mv server.git/hooks/pre-receive kit/pre-receive.off'
run 'cd asha'
run 'git log --oneline -2'
run 'git pull -q --no-rebase 2>&1'
run 'git push 2>&1'
run 'cd ..'
run "git -C server.git log --oneline main -S'DUMMY-KEY'"
run 'git -C server.git show $first:.env | head -1'

snip 13-recovery-server
run 'cd cleanup.git'
run 'git push --force --mirror origin 2>&1'
run 'cd ..'
run 'mv kit/pre-receive.off server.git/hooks/pre-receive'
run 'git -C server.git gc -q --prune=now'
run_rc 'git -C server.git cat-file -t $first'

snip 14-recovery-clone
run 'cd asha'
run 'git fetch -q 2>&1'
run 'git reflog show origin/main'
run 'git reflog show main -3'
run 'old=$(git reflog show main --format=%h | tail -1); echo $old'
note 'Undo the merge, then replay only her own commit onto the clean history.'
run "git reset -q --hard 'main@{1}'"
run 'git rebase -q --onto origin/main $old 2>&1'
run 'git log --oneline -3'

snip 15-recovery-clone-prune
run 'git tag -l | xargs git tag -d'
run 'git fetch -q --prune --tags'
run 'git reflog expire --expire=now --all && git gc -q --prune=now'
run_rc 'git cat-file -t $first'
run 'git push 2>&1'
run 'cd ..'

snip 16-verification
run './provider/keyctl status DUMMY-KEY-not-a-real-secret-12345'
run 'git -C server.git log --oneline main'
run "git -C server.git grep -l DUMMY-KEY \$(git -C server.git rev-list --all) | wc -l"
run 'git -C server.git fsck --no-progress --unreachable | wc -l'
run 'for c in ragdesk asha ravi; do printf "%s: " $c; git -C $c cat-file -t $first 2>&1; done'
run 'cat refs-after.txt | cut -c1-7,41-'
lab_end

#!/usr/bin/env bash
# Chapter 21B, sections 21B.10 and 21B.11: a committed secret stays in history after the file
# is deleted, and the built-in commands that find it (git log -S, git log -G, git grep over
# git rev-list --all).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b find-secret
fx_ragdesk
fx_ragdesk_notebook

snip 01-the-leak
run 'cd ragdesk'
run 'git log --oneline --decorate'
run 'cat .env'

snip 02-delete-is-not-removal
run 'git rm --cached -q .env'
run "printf '.env\n' > .gitignore"
run "git add .gitignore && git commit -q -m 'Stop tracking .env and ignore it'"
run 'git ls-files'
run_rc 'git grep -n DUMMY-KEY'
note 'The tip is clean. The commit that added the file still has it:'
run 'git show HEAD~4:.env'

snip 03-pickaxe
run "git log --oneline -S'DUMMY-KEY-not-a-real-secret' -- .env"
run "git log --oneline --all -S'DUMMY-KEY-not-a-real-secret'"

snip 04-pickaxe-patch
run "git log -p --format='commit %h%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' -S'DUMMY-KEY-not-a-real-secret' --diff-filter=A"

snip 05-regex
run "git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'"
run "git log --oneline --all --name-only --format='%h %s' -G'Bearer [A-Za-z0-9-]+'"

snip 06-grep-all-commits
run "git grep -n 'DUMMY-KEY' \$(git rev-list --all) | cut -c1-9,41-"
blank
note 'Which files, in how many commits:'
run "git grep -l -E 'DUMMY-(KEY|TOKEN)' \$(git rev-list --all) | cut -d: -f2 | sort | uniq -c"

snip 07-which-refs
run 'first=$(git log --all --format=%H --diff-filter=A -- .env)'
run 'git log --oneline -1 $first'
run 'git branch -a --contains $first'
run 'git tag --contains $first'

snip 08-server-still-has-it
run 'git push -q origin main'
run_rc 'git -C ../server.git grep -c DUMMY-KEY main'
run "git -C ../server.git grep -n 'DUMMY-KEY' v0.2.0 -- .env"
lab_end

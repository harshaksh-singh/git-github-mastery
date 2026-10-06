#!/usr/bin/env bash
# Chapter 21B, section 21B.5: author and committer fields are text that the person running
# Git supplies. Nothing in Git checks them. (Chapter 14B, section 14B.18 shows the signed case.)
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21b identity-assertion
quiet 'git init billing-api'
cd billing-api || exit 1
printf 'RATE = 0.18\n' > tax.py
quiet "git add -A && git commit -m 'Add tax rate'"

snip 01-assert-anything
run "printf 'RATE = 0.0\n' > tax.py"
run "GIT_AUTHOR_NAME='Asha Rao' GIT_AUTHOR_EMAIL=asha@example.com GIT_COMMITTER_NAME='Asha Rao' GIT_COMMITTER_EMAIL=asha@example.com git commit -q -am 'Set tax rate to zero'"
run "git log --format='%h author=%an <%ae>  committer=%cn <%ce>  signature=%G?'"

snip 02-the-object
run 'git cat-file -p HEAD'
lab_end

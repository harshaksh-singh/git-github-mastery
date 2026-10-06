#!/usr/bin/env bash
# Chapter 14D, sections 14D.2 to 14D.4: what this Git does today, the four settings that choose
# the Git 3.0 defaults (or refuse them) ahead of time, and two commands that already announce
# their removal.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14d git3-optin

snip 01-build
run 'git version'
run 'git version --build-options | grep -e rust -e default'

snip 02-today
note 'The lab configuration sets init.defaultBranch. Remove it to see what Git 2.55 does on its own:'
run 'git config unset --global init.defaultBranch'
run 'git init today 2>&1 | grep -v "^hint: *$"'
run 'git -C today symbolic-ref HEAD'
run 'git -C today rev-parse --show-object-format --show-ref-format'

snip 03-opt-in
run 'git config set --global init.defaultBranch main'
run 'git config set --global init.defaultObjectFormat sha256'
run 'git config set --global init.defaultRefFormat reftable'
run 'git init tomorrow'
run 'git -C tomorrow symbolic-ref HEAD'
run 'git -C tomorrow rev-parse --show-object-format --show-ref-format'
run 'cat tomorrow/.git/config'

snip 04-new-repositories-only
note 'The settings act when a repository is created. An existing repository keeps what it has,'
note 'and a clone takes its object format from the source and its ref format from your settings:'
run 'git -C today rev-parse --show-object-format --show-ref-format'
quiet "cd today && printf 'x\n' > a.txt && git add a.txt && git commit -m 'First commit' && cd .."
run 'git clone -q today today-clone'
run 'git -C today-clone rev-parse --show-object-format --show-ref-format'

snip 05-opt-out
note 'The same keys keep the old behavior after 3.0, for the tools that need it:'
run 'git config set --global init.defaultObjectFormat sha1'
run 'git config set --global init.defaultRefFormat files'
run 'git init -q legacy-style'
run 'git -C legacy-style rev-parse --show-object-format --show-ref-format'
run 'git config list --global | grep init'

snip 06-removals
run 'git -C today whatchanged -1 2>&1 | sed -n "1,5p;\$p"'
run_rc 'git -C today whatchanged -1 > /dev/null 2>&1'
run 'git -C today log -1 --raw --no-merges --format="%h %s"'

lab_end

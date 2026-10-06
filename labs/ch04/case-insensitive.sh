#!/usr/bin/env bash
# The case-insensitive filesystem trap on macOS: a rename that differs only by case is
# invisible to Git, and two tracked paths that differ only by case cannot both exist on disk.
# Chapter 4, section 4.12.
#
# This demo assumes the default macOS volume format (APFS, case-insensitive). On a
# case-sensitive volume the output differs, and that difference is the lesson.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 case-insensitive

snip 01-probe
run 'git init support-bot'
run 'cd support-bot'
run 'git config get core.ignoreCase'
mkdir -p src
printf 'TOP_K = 5\n' > src/Config.py
printf 'from Config import TOP_K\n' > src/app.py
quiet 'git add . && git commit -m "Add service skeleton"'

snip 02-invisible-rename
run 'git ls-files'
run 'mv src/Config.py src/config.py'
run 'ls src'
run 'git status'
run 'git add -A'
run 'git ls-files'

snip 03-git-mv
note 'The file on disk already has the new name. The index does not. "git mv" renames the index entry.'
run 'git mv src/Config.py src/config.py'
run 'git status --short'
run 'git ls-files'
quiet 'git commit -m "Rename Config.py to config.py"'

snip 04-collision-made-on-linux
note 'A teammate on Linux commits two files whose names differ only by case.'
note 'A Mac cannot hold both on disk, so this imitation writes the index directly.'
run 'cd ..'
run 'git init -q linux-teammate && cd linux-teammate'
run "five=\$(printf 'TOP_K = 5\n' | git hash-object -w --stdin)"
run "eight=\$(printf 'TOP_K = 8\n' | git hash-object -w --stdin)"
run 'git update-index --add --cacheinfo 100644,$five,src/Config.py'
run 'git update-index --add --cacheinfo 100644,$eight,src/config.py'
run 'git commit -q -m "Add config module"'
run 'git ls-tree -r HEAD'

snip 05-clone-on-mac
run 'cd ..'
run 'git clone linux-teammate mac-clone'
run 'cd mac-clone'
run 'ls src'
run 'git status --short'
run 'git diff'

snip 06-detect-and-fix
note 'Detect: fold every tracked path to lower case and look for duplicates.'
run "git ls-files | tr '[:upper:]' '[:lower:]' | sort | uniq -d"
note 'Fix: stop tracking one of the two names, commit, and check the other one out again.'
run 'git rm --cached src/Config.py'
run 'git commit -q -m "Remove Config.py, which collides with config.py on case-insensitive filesystems"'
run 'git restore .'
run 'git status --short'
run 'git ls-files'

lab_end

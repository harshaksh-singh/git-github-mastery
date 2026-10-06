#!/usr/bin/env bash
# Chapter 3, section 3.8, root-cause box: git fsck and reflog entries dated in the future.
# Two repositories with the same commands and different dates. git fsck skips reflog entries
# whose timestamp is later than the moment fsck starts, so a commit that only a future-dated
# reflog entry refers to is reported as dangling. git gc has no such rule and keeps the commit.
#
# Source of the rule: commit f6b262581a885a11e3e817bf635303e40b640f2a in git/git,
# "fsck: snapshot default refs before object walk" (January 2026). builtin/fsck.c contains the
# check at the v2.53.0 tag and not at v2.52.0, so the rule is in Git 2.53.0 and later. Verified
# locally: Git 2.55.0 applies it, Apple Git 2.50.1 does not. fsck reads the real clock
# (time(NULL)), not GIT_TEST_DATE_NOW.
# Deterministic for any real date between the two dates used here (2001 and 2099).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 fsck-reflog-clock

cat > make-history.sh <<'SCRIPT'
#!/bin/sh
# make-history.sh <directory> <date>
# Two commits and a reset that drops the second one, all recorded at <date>.
export GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2"
git init --quiet "$1" && cd "$1" || exit 1
echo 'retry_limit = 3' > config.toml
git add config.toml && git commit --quiet -m 'Add configuration'
echo 'retry_limit = 5' > config.toml
git commit --quiet -am 'Raise retry limit'
git reset --quiet --hard HEAD~1
SCRIPT

snip 01-script
run 'cat make-history.sh'
run "sh make-history.sh dated-2001 '2001-01-01T12:00:00+0530'"
run "sh make-history.sh dated-2099 '2099-01-01T12:00:00+0530'"

snip 02-fsck
note 'Reflog entries in the past count as starting points. Nothing is dangling:'
run 'git -C dated-2001 reflog --date=short'
run_rc 'git -C dated-2001 fsck'
note 'Reflog entries dated after "now" are skipped, so the dropped commit looks dangling:'
run 'git -C dated-2099 reflog --date=short'
run_rc 'git -C dated-2099 fsck'
note 'The commit is in the reflog either way, and the reflog is what you recover from:'
run 'git -C dated-2099 log --oneline -1 "HEAD@{1}"'

snip 03-gc-keeps-it
note 'Garbage collection does not apply the clock rule. Even with no grace period, the commit stays:'
run 'git -C dated-2099 gc --quiet --prune=now'
run 'git -C dated-2099 cat-file -t "HEAD@{1}"'
run 'git -C dated-2099 count-objects -v | grep -e count -e in-pack'
note 'fsck still calls it dangling. "Dangling" is a statement about fsck starting points, not a verdict:'
run_rc 'git -C dated-2099 fsck'

lab_end

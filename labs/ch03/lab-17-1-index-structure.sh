#!/usr/bin/env bash
# Lab 17.1 replay: read the index as a data structure.
# Header, entries and extensions; what "git add" changes; the stat cache; conflict stages;
# then the failure scenario (a corrupt index) and its recovery.
# The stat numbers themselves are in the volatile companion lab-17-1-index-stat-volatile.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 lab-17-1-index-structure
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-17-1-index.sh" || exit 1

snip 01-entries
run 'git ls-files --stage'
run 'head -c 12 .git/index | xxd'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index'

snip 02-add
run "printf 'def health():\\n    return \"ok\"\\n' > src/health.py"
run 'git add src/health.py'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index'
note 'The entry points at a blob that "git add" has already written:'
run 'git cat-file -t 7dd51168'
run 'git commit --quiet -m "Add health handler"'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep extension'

snip 03-stat-cache
run 'touch -t 202001010000 src/server.py'
run 'git diff-files'
run 'git status --short'
run 'git diff-files'

snip 04-stages
run_rc 'git merge feature/timeouts'
run 'git ls-files --stage'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index'
run 'git show :1:config.toml'
run 'git show :3:config.toml'

snip 05-resolve
run "printf 'retry_limit = 3\\ntimeout_s = 60\\n' > config.toml"
run 'git add config.toml'
run 'git ls-files --stage config.toml'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e extension -e checksum'
run 'git commit --quiet -m "Merge feature/timeouts"'

snip 06-failure
note 'Failure scenario. Stage one new file, leave one edit unstaged, then damage the index.'
run "printf 'log_level = \"info\"\\n' > logging.toml"
run 'git add logging.toml'
run "printf 'retry_limit = 5\\ntimeout_s = 60\\n' > config.toml"
run 'git status --short'
run "printf 'JUNK' | dd of=.git/index conv=notrunc 2>/dev/null"
run 'head -c 12 .git/index | xxd'
run_rc 'git status'
note 'History does not live in the index. It is unharmed:'
run 'git log --oneline -1'

snip 07-recovery
note 'Throw the damaged index away and rebuild it from HEAD. The working tree is not touched.'
run 'rm .git/index'
run 'git reset'
run 'git status --short'
note 'What was lost is the staging of logging.toml. Its blob is still in the object database:'
run 'git fsck'
run 'git cat-file -p e8b40360'

snip 08-dangling-tree
note 'The dangling tree is a leftover of the conflicted merge in step 4:'
run 'git ls-tree 28956793'
run 'git cat-file -p 28956793:config.toml'

snip 09-verification
run 'git add logging.toml'
run 'git status --short'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e checksum'

lab_end

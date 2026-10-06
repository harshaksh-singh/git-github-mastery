#!/usr/bin/env bash
# Chapter 3, section 3.12: the index file as a data structure.
# Header, entries, flags, stages and extensions, read with git ls-files and with
# labs/ch03/read-index.py; then the cached stat data at work.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 index-file
build_inference_service

snip 01-stage
run 'git ls-files --stage'
note 'The first twelve bytes of the file: signature, version, number of entries.'
run 'head -c 12 .git/index | xxd'

snip 02-read-index
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index'

snip 03-stat-cache
note 'Change the modification time of a file, not its content.'
run 'touch -t 202001010000 config.toml'
note 'Plumbing compares cached stat data only, and reports the path as possibly changed:'
run 'git diff-files'
note 'Porcelain re-reads the file, finds the same content, and refreshes the cached stat data:'
run 'git status --short'
run 'git diff-files'

snip 04-copied-repository
note 'Copy the whole repository, as a backup restore or a CI cache would.'
run 'cp -R . ../restored-copy'
run 'git -C ../restored-copy diff-files --name-status'
run_rc 'git -C ../restored-copy diff-files --quiet'
note 'New inode numbers and change times: every cached entry is stale. One refresh fixes it.'
run 'git -C ../restored-copy update-index --refresh'
run_rc 'git -C ../restored-copy diff-files --quiet'

snip 05-flags
run 'git update-index --assume-unchanged run.sh'
run 'git update-index --skip-worktree config.toml'
run "printf '# Inference service\\n' > README.md"
run 'git add --intent-to-add README.md'
note 'Only the header and the entries that carry a flag:'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e "\["'
quiet 'git update-index --no-assume-unchanged run.sh'
quiet 'git update-index --no-skip-worktree config.toml'
quiet 'git rm --cached --quiet README.md && rm README.md'

# Two branches that change the same line, for the stages.
quiet 'git switch -c feature/timeouts'
as asha
quiet "sed -e 's/timeout_s = 30/timeout_s = 60/' config.toml > config.tmp && mv config.tmp config.toml && git commit -am 'Double the timeout'"
as you
quiet 'git switch main'
quiet "sed -e 's/timeout_s = 30/timeout_s = 45/' config.toml > config.tmp && mv config.tmp config.toml && git commit -am 'Raise timeout to 45 seconds'"

snip 06-stages
run_rc 'git merge feature/timeouts'
note 'One path, three entries: stage 1 is the merge base, 2 is ours, 3 is theirs.'
run 'git ls-files --unmerged'
run 'git cat-file -p :1:config.toml | grep timeout'
run 'git cat-file -p :2:config.toml | grep timeout'
run 'git cat-file -p :3:config.toml | grep timeout'

snip 07-resolve
run 'git restore --theirs config.toml'
run 'git add config.toml'
run 'git ls-files --stage config.toml'
note 'The three stages moved into the "resolve undo" extension (REUC):'
run 'python3 "$COURSE_ROOT/labs/ch03/read-index.py" .git/index | grep -e header -e extension -e checksum'
run 'git commit --quiet -m "Merge feature/timeouts"'

snip 08-version-4
run 'git update-index --show-index-version'
run 'wc -c < .git/index'
run 'git update-index --index-version 4'
run 'head -c 12 .git/index | xxd'
run 'wc -c < .git/index'
run 'git update-index --index-version 2'

lab_end

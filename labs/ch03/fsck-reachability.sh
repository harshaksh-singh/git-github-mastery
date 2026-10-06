#!/usr/bin/env bash
# Chapter 3, section 3.8: reachability and git fsck.
# A healthy repository, then objects that nothing refers to: a blob that was staged and unstaged,
# and a commit whose only branch was deleted.
#
# Clock note: plain "git fsck" also starts from reflog entries, except entries dated after the
# moment fsck starts (Git 2.53 and later; fsck-reflog-clock.sh demonstrates that rule and names
# its source). The lab clock is in the past, so every reflog entry made here counts, on whatever
# day the demo runs. --no-reflogs is used below to show what the refs and the index alone reach.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 fsck-reachability
build_inference_service

snip 01-healthy
note 'A healthy repository: no output, exit status 0.'
run_rc 'git fsck'

snip 02-dangling-blob
note 'Stage a file, then change your mind and unstage it.'
run "printf 'api_token = \"test-0000-not-a-real-token\"\\n' > secrets.toml"
run 'git add secrets.toml'
run 'git rm --cached --quiet secrets.toml'
run 'git status --short'
note 'The index entry is gone. The blob that "git add" wrote is not:'
run 'git fsck'
run 'git cat-file -p e6773e7e'

snip 03-unreachable
note 'A commit on a branch, and then the branch is deleted.'
run 'git switch --quiet -c experiment/cache'
run "printf 'cache_ttl_s = 300\\n' >> config.toml"
run 'git commit --quiet -am "Add cache TTL"'
run 'git switch --quiet main'
run 'git branch -D experiment/cache'
note 'Starting from refs and the index only (--no-reflogs), four objects are unreachable:'
note 'the commit, its tree, its new blob, and the blob that was unstaged earlier.'
run 'git fsck --no-reflogs --unreachable'
note 'Only the objects that nothing at all points to are called dangling:'
run 'git fsck --no-reflogs'

snip 04-reflog-still-holds-it
note 'The HEAD reflog still records the commit, which is what keeps it safe for now:'
run 'git reflog -3'
run 'git log --oneline -1 "HEAD@{1}"'
note 'With reflog entries as starting points again, only the blob is left over:'
run 'git fsck'

lab_end

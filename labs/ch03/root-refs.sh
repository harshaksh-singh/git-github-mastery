#!/usr/bin/env bash
# Chapter 3, section 3.10: root refs and the two pseudorefs.
# FETCH_HEAD and MERGE_HEAD can hold several object IDs and cannot be written with update-ref;
# ORIG_HEAD and its relatives are ordinary refs in the root of the hierarchy. None of them is a
# starting point for reachability: a commit that only FETCH_HEAD names is deleted by a garbage
# collection without a grace period ("--prune=now" does not depend on any clock).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 root-refs
build_inference_service

# A bare repository plays the server. A teammate's clone holds one commit that was never pushed.
quiet 'git init --bare ../server.git'
quiet 'git remote add origin ../server.git'
quiet 'git push -u origin main feature/batching'
quiet 'git clone ../server.git ../teammate'
as asha
quiet "git -C ../teammate switch -c fix/timeout && printf 'retry_limit = 3\ntimeout_s = 20\nbatch_size = 8\n' > ../teammate/config.toml && git -C ../teammate commit -am 'Lower the timeout to 20 seconds'"
as you
# Two small branches for a merge of more than one branch at once.
quiet "git switch -c topic/metrics main && printf 'def metrics():\n    return {}\n' > src/handlers/metrics.py && git add . && git commit -m 'Add metrics handler'"
quiet "git switch -c topic/tracing main && printf 'def trace():\n    return None\n' > src/handlers/tracing.py && git add . && git commit -m 'Add tracing handler'"
quiet 'git switch main'

snip 01-fetch-head
run 'git fetch origin'
note 'One line per fetched branch: object ID, a marker for "git pull", and where it came from.'
run 'cat .git/FETCH_HEAD'
note 'Used as a revision, FETCH_HEAD means its first line:'
run 'git rev-parse FETCH_HEAD'

snip 02-merge-head
note 'A merge of two branches at once, stopped before the commit is made:'
run 'git merge --no-commit topic/metrics topic/tracing'
note 'MERGE_HEAD holds one line per branch being merged. ORIG_HEAD holds where main was:'
run 'cat .git/MERGE_HEAD'
run 'cat .git/ORIG_HEAD'
run 'ls -A .git'

snip 03-root-refs
note 'The refs outside refs/, as Git lists them. The two pseudorefs are not in the list:'
run 'git for-each-ref --include-root-refs | grep -v refs/'
note 'A root ref is an ordinary ref, so update-ref writes it. A pseudoref is refused:'
run_rc 'git update-ref ORIG_HEAD HEAD~1'
run_rc 'git update-ref MERGE_HEAD HEAD~1'
run 'git reflog exists ORIG_HEAD; echo "exit status: $?"'
run 'git merge --abort'

snip 04-not-a-starting-point
note 'A branch of a teammate, fetched by path without a destination ref. It lands in FETCH_HEAD only:'
run 'git fetch ../teammate fix/timeout'
run 'git log --oneline -1 FETCH_HEAD'
note 'No ref under refs/ and no reflog entry names that commit, so fsck reports it.'
note '(The dangling tree is the result of the two-branch merge that was aborted above.)'
run 'git fsck'
note 'A garbage collection without a grace period deletes it. The name stays behind and names nothing:'
run 'git gc --quiet --prune=now'
run 'cat .git/FETCH_HEAD'
run_rc 'git log --oneline -1 FETCH_HEAD'

lab_end

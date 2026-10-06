#!/usr/bin/env bash
# Lab 1.3: same content, same ID, in two repositories. Blobs, trees and, when every input
# is pinned, even commits. Then an invisible byte breaks the equality.
# The commit dates are given on the command line, so a learner who types these commands by
# hand in labs/shell gets the same commit IDs as this replay.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 lab-01-3-same-content-same-id

snip 01-blobs
run 'git init -q laptop'
run 'git init -q server'
run "printf 'temperature: 0.2\n' > laptop/eval.yaml"
run "printf 'temperature: 0.2\n' > server/eval.yaml"
run 'git -C laptop add eval.yaml'
run 'git -C server add eval.yaml'
run 'git -C laptop ls-files --stage'
run 'git -C server ls-files --stage'

snip 02-trees
run 'git -C laptop write-tree'
run 'git -C server write-tree'

snip 03-commits
run "when='2026-09-07T12:00:00+05:30'"
run 'GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C laptop commit -q -m "Add eval settings"'
run 'GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C server commit -q -m "Add eval settings"'
run 'git -C laptop rev-parse HEAD'
run 'git -C server rev-parse HEAD'
run 'git -C laptop cat-file -p HEAD'

snip 04-one-second-later
run 'git init -q ci'
run "printf 'temperature: 0.2\n' > ci/eval.yaml"
run 'git -C ci add eval.yaml'
run "when='2026-09-07T12:00:01+05:30'"
run 'GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when git -C ci commit -q -m "Add eval settings"'
run "git -C ci rev-parse HEAD 'HEAD^{tree}'"
run "git -C laptop rev-parse HEAD 'HEAD^{tree}'"

snip 05-invisible-byte
note 'Failure scenario: a file that looks the same and hashes differently.'
run 'mkdir export'
run "printf 'temperature: 0.2\r\n' > export/eval.yaml"
run 'git hash-object export/eval.yaml'
run 'git hash-object laptop/eval.yaml'

snip 06-diagnose
run_rc 'cmp export/eval.yaml laptop/eval.yaml'
run 'od -c export/eval.yaml'
run 'od -c laptop/eval.yaml'

snip 07-repair
note 'Recovery: remove the carriage return.'
run "tr -d '\r' < export/eval.yaml > export/eval.yaml.lf"
run 'mv export/eval.yaml.lf export/eval.yaml'

snip 08-verify
run 'git hash-object export/eval.yaml'
run_rc 'cmp export/eval.yaml laptop/eval.yaml'

lab_end

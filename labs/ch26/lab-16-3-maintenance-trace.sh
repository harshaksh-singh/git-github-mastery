#!/usr/bin/env bash
# Lab 16.3 replay: trace a maintenance run, predict the second one, and diagnose a run that
# silently does nothing because of a stale lock file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 lab-16-3-maintenance-trace
LAB_REPLAY=1 . "$LAB_SCRIPT_DIR/setup-16-3-maintenance.sh" || exit 1
cd orbit || exit 1

snip 01-before
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'find .git/refs -type f | wc -l'
run_rc 'ls .git/objects/info .git/packed-refs'
run_rc 'git maintenance is-needed --auto'

snip 02-trace
run 'GIT_TRACE="$PWD/../trace-1.log" git maintenance run'
run "sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'"

snip 03-after
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run "find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\\{40\\}/ID/' | sort"
run 'find .git/refs -type f | wc -l'
run 'wc -l < .git/packed-refs'
run_rc 'git maintenance is-needed --auto'

snip 04-checkpoint
note 'Three commits, then a second run. Predict the repack line before you look.'
run "printf 'timeout_ms: 700\\nupstream: ranker\\n' > services/gateway/config.yaml && git commit -q -am 'gateway: lower the upstream timeout to 700 ms'"
run "printf 'top_k: 20\\nmodel: overlap-v1\\n' > services/ranker/config.yaml && git commit -q -am 'ranker: return the top 20'"
run "printf 'BATCH_SIZE = 1000\\n' > services/ingest/settings.py && git commit -q -am 'ingest: raise the batch size to 1000'"
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'GIT_TRACE="$PWD/../trace-2.log" git maintenance run'
run "sed -n 's/.*trace: run_command: git //p' ../trace-2.log | grep -e '^repack'"
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'

snip 05-failure
note 'Failure scenario: a maintenance process was killed and left its lock file behind.'
run ': > .git/objects/maintenance.lock'
run "printf 'epochs: 20\\nlearning_rate: 0.0003\\nbatch_size: 32\\n' > pipelines/training/config.yaml && git commit -q -am 'training: train for 20 epochs'"
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
note 'Maintenance reports success:'
run_rc 'git maintenance run'
note 'and has done nothing:'
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'GIT_TRACE="$PWD/../trace-3.log" git maintenance run'
run "grep -c 'run_command' ../trace-3.log"

snip 06-diagnosis
note 'Without a terminal on standard error, maintenance is quiet. Ask it to speak:'
run_rc 'git maintenance run --no-quiet'
run 'ls .git/objects/*.lock'
note 'The lock is an empty file. A running maintenance process holds the same file.'
run 'wc -c < .git/objects/maintenance.lock'

snip 07-recovery
note 'After checking that no maintenance process is running for this repository:'
run 'rm .git/objects/maintenance.lock'
run_rc 'git maintenance run --no-quiet'
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'

snip 08-verification
run_rc 'git fsck'
run_rc 'git multi-pack-index verify'
run_rc 'git commit-graph verify'
run_rc 'ls .git/objects/*.lock'
run 'git log --oneline -4'

lab_end

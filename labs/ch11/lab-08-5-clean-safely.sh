#!/usr/bin/env bash
# Lab 8.5 replay: read the four dry runs of "git clean", then remove only what can be
# regenerated. Failure: "git clean -f -d -x" for a "pristine tree". Recovery: prove that Git
# has nothing to give back, then rebuild what can be rebuilt.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-5-clean-safely
fx_08_5

snip 01-status
run 'cd trainer'
run 'git status -s --ignored'

snip 02-refused
run_rc 'git clean'

snip 03-dry-runs
run 'git clean -n'
run 'git clean -n -d'
run 'git clean -n -d -X'
run 'git clean -n -d -x'

snip 04-targeted
run "git clean -n -d -X -e '!.env' -e '!checkpoints/'"
run "git clean -f -d -X -e '!.env' -e '!checkpoints/'"
run 'git clean -n tmp_debug.txt'
run 'git clean -f tmp_debug.txt'
run 'git status -s --ignored'

snip 05-failure
run 'git clean -f -d -x'
run 'git status -s --ignored'
run 'ls -A'

snip 06-recovery
run 'git fsck'
run "printf 'TRACKING_TOKEN=local-dev-only\nDATA_ROOT=/data/corpus\n' | git hash-object --stdin"
run_rc 'git cat-file -t 7c1ea6ccf37927d05649eba390e0f9ef87b4cd9d'
run 'cp .env.example .env'
run 'cat .env'

snip 07-verification
run 'git status -s --ignored'
run 'git status -s'

lab_end

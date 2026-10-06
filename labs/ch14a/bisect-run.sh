#!/usr/bin/env bash
# Chapter 14A, section 14A.21: the same search, automated. A test script outside the repository
# answers good (0), bad (1) or untestable (125) for each commit that git bisect run checks out.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a bisect-run
fx_scorekit || exit 1
sk_check_script ../check-em.sh

snip 01-script
run 'cat ../check-em.sh'
run '../check-em.sh; echo "exit status on main: $?"'

snip 02-run
run 'git bisect start main v0.1.0'
run 'git bisect run ../check-em.sh'

snip 03-log
run 'git bisect log'
run 'git bisect reset'

snip 04-one-liner
note 'The same test without a script file. The exit status of grep is the verdict; a crash would count as bad.'
run 'git bisect start main v0.2.0~4'
run "git bisect run sh -c 'python3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null | grep -q exact_match=0.800'"
run 'git bisect reset'

snip 05-bad-exit-code
run 'git bisect start main v0.1.0'
run_rc "git bisect run sh -c 'exit 200'"
run 'git bisect reset'

snip 06-missing-script
run 'git bisect start main v0.1.0'
run_rc 'git bisect run ./check-em.sh'
run 'git bisect reset'

snip 07-dirty-tree
quiet "printf 'SMOKE_LIMIT = 10\n' >> scorekit/config.py"
note 'An uncommitted edit in scorekit/config.py, a file that differs between the commits to visit:'
run_rc 'git bisect start main v0.1.0'
run 'git bisect reset'
lab_end

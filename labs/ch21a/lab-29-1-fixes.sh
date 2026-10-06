#!/usr/bin/env bash
# Lab 29.1 replay, second half: the reference fixes of labs/ch21a/fixed/ applied to the five
# teaching workflows, shown as Git diffs (for the solutions file), and the verification scans.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a lab-29-1-fixes
. "$LAB_SCRIPT_DIR/fixture.bash"
wf_repo
cp "$LAB_SCRIPT_DIR"/fixed/v*.yml .github/workflows/
cd .github/workflows || exit 1

snip 01-stat
run 'git diff --stat'

for n in 1 2 3 4 5; do
  f=$(ls v$n-*.yml)
  snip "1$n-diff-v$n"
  run "git diff -U2 -- $f | grep -v '^index '"
done

snip 20-verify-patterns
note 'After your fixes, each of these scans must come back empty (exit status 1 from grep).'
run_rc "grep -n 'pull_request_target\\|allow-unsafe\\|write-all' v*.yml"
run_rc "grep -n 'uses:' v*.yml | grep -vE '@[0-9a-f]{40}( |\$)'"
run "awk '/run: \\|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:\$/ {inrun=0} inrun && /\\\$\\{\\{/ {print FILENAME \":\" FNR \":\" \$0}' v*.yml"
run_rc "grep -n 'run:.*\${{' v*.yml"

snip 21-verify-scope
note 'Every workflow declares permissions, and the one secret is named in one step.'
run "grep -c '^permissions:' v*.yml"
run "grep -n -B2 'secrets\\.' v*.yml"

snip 22-commit
run 'git add .'
run 'git commit -q -m "Fix one weakness in each of five workflows"'
run 'git status --short'

lab_end

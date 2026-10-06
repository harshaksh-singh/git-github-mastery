#!/usr/bin/env bash
# End-to-end replay of the capstone: the company repository, then all eight stages in order.
# For each stage it applies the incident, proves that the stage's check rejects that state,
# applies the model solution, and requires that the check then passes. The transcript is the
# summary printed in solutions/capstone-walkthrough.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$COURSE_ROOT/capstone/lib/capstone-lib.bash"
lab_begin capstone end-to-end
. "$CAP_HOME/lib/base.bash"
cap_build_base

snip 01-company
run 'cd you'
run 'git log --oneline --graph --decorate origin/main'
run 'git tag -n1'
run '../pr list'
run 'git ls-files'
run 'cd ..'

snip 02-stages
k=1
fail=0
while [ "$k" -le 8 ]; do
  cap_inject "$k"
  if cap_check "$k" > /dev/null 2>&1; then before=PASS; fail=1; else before='NOT YET'; fi
  cap_model "$k"
  if cap_check "$k" > /dev/null 2>&1; then after=PASS; else after='NOT YET'; fail=1; fi
  printf 'stage %s  %-26s check before the solution: %-8s after: %s\n' "$k" "$(cap_slug "$k" | cut -c4-)" "$before" "$after"
  k=$((k + 1))
done

snip 03-final-state
run 'cd you'
run 'git fetch --quiet --prune'
run 'git log --oneline --graph --first-parent --decorate v1.3.0..origin/main'
run 'git log --oneline --decorate v1.3.1..origin/release/1.3'
run '../pr list --all | tail -n 12'
run 'git tag -n1'
lab_end
[ "$fail" -eq 0 ] || { printf 'end-to-end: a check did not behave as required\n' >&2; exit 99; }

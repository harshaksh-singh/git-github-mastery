#!/usr/bin/env bash
# Read-only verification of the final-test lab "merge". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin merge "${1:-}"
S=server.git
old=$(noted main)
new=$(rev $S refs/heads/main)
expect 'main on the server still contains the two merges (nothing was rewritten)' is_ancestor $S "$old" refs/heads/main
if [ -n "$new" ] && [ "$new" != "$old" ]; then ok 'main on the server has at least one new commit'; else bad 'main on the server has no new commit'; fi
expect 'the rename is still on main: store.py defines get_answer' sh -c "git -C $S show main:answerbank/store.py | grep -q '^def get_answer('"
expect 'the bulk export is still on main' git -C $S cat-file -e main:answerbank/export.py
expect_eq 'tests/smoke.sh is unchanged' "$(rev $S main:tests/smoke.sh)" "$(noted smoke)"
miss=0
for name in $(git -C $S grep -hoE 'store\.[a-z_]+\(' main -- answerbank 2>/dev/null | sed -e 's/store\.//' -e 's/($//' | sort -u); do
  git -C $S show main:answerbank/store.py 2>/dev/null | grep -q "^def $name(" || miss=$((miss + 1))
done
if [ "$miss" -eq 0 ]; then ok 'every store.<name>( call on main has a definition (the smoke test passes)'; else bad "$miss call(s) to the store on main have no definition (the smoke test fails)"; fi
expect_eq 'your main equals main on the server' "$(rev you refs/heads/main)" "$new"
expect 'nothing is staged, modified or untracked in your clone' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end

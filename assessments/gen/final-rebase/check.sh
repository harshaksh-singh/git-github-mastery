#!/usr/bin/env bash
# Read-only verification of the final-test lab "rebase". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin rebase "${1:-}"
R=you
B=feature/span-match
base=$(noted base)
expect "HEAD is on $B" on_branch $R "$B"
expect_not 'no rebase or other operation is left in progress' in_progress $R
expect "the branch sits on top of the current origin/main" is_ancestor $R "$base" "refs/heads/$B"
expect_eq 'the branch has exactly these three commits, in this order' "$(subjects $R "$base..refs/heads/$B")" 'Add span matcher | Add overlap scoring | Add fuzzy threshold'
expect_eq 'the files at the tip are what the five commits and origin/main produce together' "$(rev $R "refs/heads/$B^{tree}")" "$(noted tree)"
expect_eq 'no commit of the branch touches debug.log' "$(git -C $R log --format=%h "$base..refs/heads/$B" -- debug.log 2>/dev/null | wc -l | tr -d ' ')" 0
expect_not 'the commit "Add span matcher" no longer contains the misspelled name' sh -c "git -C $R show 'refs/heads/$B~2:citecheck/match.py' | grep -q treshold"
expect 'the commit "Add overlap scoring" adds citecheck/overlap.py' sh -c "git -C $R diff --name-only 'refs/heads/$B~2' 'refs/heads/$B~1' | grep -Fxq citecheck/overlap.py"
expect_eq 'main on the server was not touched' "$(rev server.git refs/heads/main)" "$base"
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end

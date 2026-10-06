#!/usr/bin/env bash
# Read-only verification of exercise 11.9. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m11-judgekit judgekit/.git "${1:-}"
R=judgekit
want=$(id_of $R v1.1.0 "Treat 'partially correct' as a pass")
have=$(git -C $R rev-parse -q --verify 'refs/tags/answer/first-bad^{commit}' 2>/dev/null)
same 'the tag answer/first-bad names the commit that lowered the agreement' "$have" "$want"
expect 'no bisect session is open' no_operation $R
same 'HEAD is on main' "$(git -C $R symbolic-ref -q --short HEAD)" main
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
expect 'no existing commit was rewritten (v1.1.0 is an ancestor of main)' git -C $R merge-base --is-ancestor v1.1.0 main
score=$(cd $R && python3 -B check_agreement.py 2>/dev/null | awk '$1=="agreement"{print $2}')
case "$score" in 0.9*|1.0*) ok "the check prints agreement $score on main" ;; *) bad "the check prints agreement '${score:-nothing}' on main (expected at least 0.90)" ;; esac
check_end
